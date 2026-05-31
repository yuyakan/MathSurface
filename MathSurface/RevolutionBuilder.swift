//
//  RevolutionBuilder.swift
//  MathSurface
//
//  回転軸の種類定義のみ。実際の3D描画は RevolutionSceneView で行う。
//

import Foundation

enum RevolutionAxis: String, CaseIterable, Identifiable {
    case x, y
    var id: String { rawValue }
    var label: String {
        self == .x
            ? String(localized: "x軸まわり")
            : String(localized: "y軸まわり")
    }
    var revolutionTitle: String {
        self == .x
            ? String(localized: "x軸回転体")
            : String(localized: "y軸回転体")
    }
}
