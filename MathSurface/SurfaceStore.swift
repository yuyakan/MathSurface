//
//  SurfaceStore.swift
//  MathSurface
//
//  タブ間で共有する状態。現在選択中の関数と選択タブを保持。
//

import SwiftUI

enum AppTab: Hashable {
    case home, gallery, formula, favorites
}

@Observable
final class SurfaceStore {
    var current: SurfaceFunction = PresetLibrary.default
    var selectedTab: AppTab = .home
    var displayRadius: Double = 10  // 表示範囲（半径）。5〜30 程度を想定

    func select(_ function: SurfaceFunction) {
        current = function
        selectedTab = .home
    }
}
