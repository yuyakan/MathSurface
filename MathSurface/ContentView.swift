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
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            GalleryTab()
                .tabItem {
                    Label("ギャラリー", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.gallery)

            FormulaTab()
                .tabItem {
                    Label("数式", systemImage: "function")
                }
                .tag(AppTab.formula)

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
