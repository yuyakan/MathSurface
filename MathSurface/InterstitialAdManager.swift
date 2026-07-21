//
//  InterstitialAdManager.swift
//  MathSurface
//

import Foundation
import GoogleMobileAds
import StoreKit
import UIKit

@MainActor
final class InterstitialAdManager: NSObject, FullScreenContentDelegate {
    static let shared = InterstitialAdManager()

    // Debugビルドではテスト広告、Releaseビルドでは本番広告を使う。
    // 本番IDで開発端末からテストするとポリシー違反になり得るため。
    private static let testAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private static let productionAdUnitID = "ca-app-pub-3155724310732667/5270726289"

    private var interstitial: InterstitialAd?
    private var isLoading = false

    private var adUnitID: String {
        #if DEBUG
        return Self.testAdUnitID
        #else
        return Self.productionAdUnitID
        #endif
    }

    private static let minIntervalSeconds: TimeInterval = 100
    private static let triggersBetweenAds = 3

    private var triggersSinceLastAd = 0
    private var lastPresentedAt: Date?

    // 広告表示の1回手前（カウント2）でレビューダイアログをリクエストする。
    // ただし最初の2回目はスキップし、2回目以降のカウント2到達時から呼ぶ。
    private static let triggersBeforeAdForReview = triggersBetweenAds - 1
    private var reviewRequestCount = 0

    private static let maxRetryDelay: TimeInterval = 60
    private var retryDelay: TimeInterval = 2

    func notifyTrigger() {
        triggersSinceLastAd += 1
        // 広告表示の1回手前でレビューをリクエスト。最初の1回目はスキップする。
        if triggersSinceLastAd == Self.triggersBeforeAdForReview {
            reviewRequestCount += 1
            if reviewRequestCount >= 2 {
                requestReview()
            }
        }
        let elapsed = lastPresentedAt.map { Date().timeIntervalSince($0) } ?? .infinity
        guard triggersSinceLastAd >= Self.triggersBetweenAds else { return }
        guard elapsed >= Self.minIntervalSeconds else { return }
        guard interstitial != nil else {
            loadAd()
            return
        }
        // シートのdismissアニメーションが完了するのを待ってからpresentする。
        // 直後にpresentするとシートに巻き込まれて即座に閉じられることがある。
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            if self.present() {
                self.triggersSinceLastAd = 0
                self.lastPresentedAt = Date()
            }
        }
    }

    func loadAd() {
        guard !isLoading, interstitial == nil else { return }
        isLoading = true
        Task {
            do {
                let ad = try await InterstitialAd.load(with: adUnitID, request: Request())
                ad.fullScreenContentDelegate = self
                self.interstitial = ad
                self.retryDelay = 2
                self.isLoading = false
            } catch {
                self.interstitial = nil
                self.isLoading = false
                self.scheduleRetry()
            }
        }
    }

    private func scheduleRetry() {
        let delay = retryDelay
        retryDelay = min(retryDelay * 2, Self.maxRetryDelay)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            self.loadAd()
        }
    }

    @discardableResult
    func present() -> Bool {
        guard let ad = interstitial,
              let root = Self.topViewController() else {
            loadAd()
            return false
        }
        ad.present(from: root)
        return true
    }

    // MARK: - FullScreenContentDelegate

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.interstitial = nil
            self.loadAd()
        }
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.interstitial = nil
            self.loadAd()
        }
    }

    // MARK: - Review

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    // MARK: - Helpers

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        // dismiss中のVCの上には広告をpresentしない（巻き込まれて即座に閉じられる）
        if let presented = root?.presentedViewController,
           !presented.isBeingDismissed {
            return topViewController(base: presented)
        }
        return root
    }
}
