//
//  ContentView.swift
//  MathSurface
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var store = SurfaceStore()
    @AppStorage("themePreference") private var themeRaw: String = ThemePreference.system.rawValue

    private var theme: ThemePreference {
        ThemePreference(rawValue: themeRaw) ?? .system
    }

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.selectedTab) {
            HomeTab()
                .tabItem {
                    Label("3D", systemImage: "cube")
                }
                .tag(AppTab.home)

            LineTab()
                .tabItem {
                    Label("2D", systemImage: "chart.xyaxis.line")
                }
                .tag(AppTab.line)

            FavoritesTab()
                .tabItem {
                    Label("お気に入り", systemImage: "star.fill")
                }
                .tag(AppTab.favorites)

            SettingsTab()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(AppTab.settings)
        }
        .tint(.indigo)
        .environment(store)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedFormula.self, inMemory: true)
}
