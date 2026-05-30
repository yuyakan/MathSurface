//
//  ContentView.swift
//  MathSurface
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var store = SurfaceStore()

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

            ComplexTab()
                .tabItem {
                    Label("複素数", systemImage: "circle.hexagongrid")
                }
                .tag(AppTab.complex)

            ProbabilityTab()
                .tabItem {
                    Label("確率", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.probability)

            FavoritesTab()
                .tabItem {
                    Label("お気に入り", systemImage: "star.fill")
                }
                .tag(AppTab.favorites)
        }
        .tint(AppTheme.accent)
        .environment(store)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedFormula.self, inMemory: true)
}
