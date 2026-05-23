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

            FavoritesTab()
                .tabItem {
                    Label("お気に入り", systemImage: "star.fill")
                }
                .tag(AppTab.favorites)
        }
        .tint(.indigo)
        .environment(store)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedFormula.self, inMemory: true)
}
