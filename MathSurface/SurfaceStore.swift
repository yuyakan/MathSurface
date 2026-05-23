//
//  SurfaceStore.swift
//  MathSurface
//
//  タブ間で共有する状態。現在選択中の関数（3D/2D）と選択タブを保持。
//

import SwiftUI

enum AppTab: Hashable {
    case home, line, favorites
}

@Observable
final class SurfaceStore {
    var current: SurfaceFunction = PresetLibrary.default
    var currentLine: LineFunction = LinePresetLibrary.default
    var selectedTab: AppTab = .home
    var displayRadius: Double = 10  // 表示範囲（半径）。3〜30 程度を想定

    // 断面: y = (xの式) の形式で xy 平面上の直線/曲線を指定。デフォルトは y = 0
    var crossSectionYFormula: String = "0"

    func select(_ function: SurfaceFunction) {
        current = function
        selectedTab = .home
    }

    func selectLine(_ function: LineFunction) {
        currentLine = function
        selectedTab = .line
    }
}
