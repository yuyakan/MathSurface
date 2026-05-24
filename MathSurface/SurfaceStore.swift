//
//  SurfaceStore.swift
//  MathSurface
//
//  タブ間で共有する状態。現在選択中の関数（3D/2D）と選択タブを保持。
//

import SwiftUI

enum AppTab: Hashable {
    case home, line, complex, probability, favorites
}

@Observable
final class SurfaceStore {
    var current: SurfaceFunction = PresetLibrary.default
    var currentLine: LineFunction = LinePresetLibrary.default
    var selectedTab: AppTab = .home
    var displayRadius: Double = 10  // 表示範囲（半径）。3〜30 程度を想定
    var compareFunction: SurfaceFunction? = nil  // 3D比較モードの2つ目の関数
    var compareLine: LineFunction? = nil          // 2D比較モードの2つ目の関数

    // 複素数タブ状態
    var complexLocusFormula: String = "|z - 1| = 2"
    var complexZ: Complex = Complex(re: 1, im: 1)
    var complexW: Complex = Complex(re: 0, im: 1)
    var complexN: Int = 5
    var complexRadius: Double = 5  // 複素平面の表示半径

    // 断面: 「y = (xの式)」「x = (yの式)」「z = (定数)」を指定
    enum CrossSectionLHS: Hashable { case yEqualsXFormula, xEqualsYFormula, zConstant }
    var crossSectionLHS: CrossSectionLHS = .yEqualsXFormula
    var crossSectionFormula: String = "0"

    func select(_ function: SurfaceFunction) {
        current = function
        selectedTab = .home
    }

    func selectLine(_ function: LineFunction) {
        currentLine = function
        selectedTab = .line
    }
}
