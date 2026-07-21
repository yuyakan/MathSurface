//
//  MathSurfaceApp.swift
//  MathSurface
//

import SwiftUI
import SwiftData

@main
struct MathSurfaceApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedFormula.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @State private var didFinishSplash: Bool = false
    @State private var didStartConsentFlow: Bool = false

    var body: some View {
        ZStack {
            ContentView()
                .opacity(didFinishSplash ? 1 : 0)
            if !didFinishSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.2)) {
                        didFinishSplash = true
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            // UIウィンドウが準備できてから、UMP同意フロー → ATT → AdMob初期化を開始する。
            guard !didStartConsentFlow else { return }
            didStartConsentFlow = true
            ConsentManager.shared.gatherConsentAndStart()
        }
    }
}
