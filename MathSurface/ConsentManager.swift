//
//  ConsentManager.swift
//  MathSurface
//

import AppTrackingTransparency
import Foundation
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// UMP（同意管理）とATT（トラッキング許可）を扱い、
/// 同意取得後に AdMob を初期化してパーソナライズ広告を有効化する。
@MainActor
final class ConsentManager {
    static let shared = ConsentManager()

    private var didStartMobileAds = false

    /// アプリ起動時に一度だけ呼ぶ。
    /// UMPの同意情報を取得し、必要ならフォームを表示、その後 ATT をリクエストして
    /// AdMob を初期化する。
    func gatherConsentAndStart() {
        let parameters = RequestParameters()
        #if DEBUG
        // シミュレータや開発端末でEEA（同意フォーム表示地域）をテストするための設定。
        let debugSettings = DebugSettings()
        debugSettings.geography = .EEA
        parameters.debugSettings = debugSettings
        #endif

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self else { return }
            if let error {
                // 同意情報の取得に失敗しても広告表示は継続する（ノンパーソナライズになり得る）。
                print("UMP consent info update error: \(error.localizedDescription)")
                self.requestATTAndStart()
                return
            }
            self.loadAndPresentFormIfNeeded()
        }
    }

    private func loadAndPresentFormIfNeeded() {
        guard let root = Self.topViewController() else {
            requestATTAndStart()
            return
        }
        ConsentForm.loadAndPresentIfRequired(from: root) { [weak self] error in
            guard let self else { return }
            if let error {
                print("UMP consent form error: \(error.localizedDescription)")
            }
            // 同意フォーム完了後（または不要だった場合）にATTをリクエストする。
            self.requestATTAndStart()
        }
    }

    private func requestATTAndStart() {
        // ATTは iOS 14 未満では存在しないため、その場合はそのまま初期化する。
        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            Task { @MainActor in
                self?.startMobileAdsIfNeeded()
            }
        }
    }

    private func startMobileAdsIfNeeded() {
        guard !didStartMobileAds else { return }
        didStartMobileAds = true
        MobileAds.shared.start { _ in
            Task { @MainActor in
                InterstitialAdManager.shared.loadAd()
            }
        }
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
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }
}
