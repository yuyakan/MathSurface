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
    var label: String { self == .x ? "x軸まわり" : "y軸まわり" }
}
