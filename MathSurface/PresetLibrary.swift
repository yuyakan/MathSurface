//
//  PresetLibrary.swift
//  MathSurface
//

import Foundation

enum PresetLibrary {
    static let all: [SurfaceFunction] = [
        // MARK: - 多項式
        SurfaceFunction(
            id: "paraboloid",
            name: "回転放物面",
            expression: "z = x² + y²",
            category: .polynomial,
            summary: "原点を底とする椀状の曲面。最小値・最適化問題の基本形。"
        ) { x, y in x * x + y * y },

        SurfaceFunction(
            id: "saddle",
            name: "鞍点（双曲放物面）",
            expression: "z = x² − y²",
            category: .polynomial,
            summary: "鞍のような形。x方向には凹、y方向には凸となる鞍点を持つ。"
        ) { x, y in x * x - y * y },

        SurfaceFunction(
            id: "monkey-saddle",
            name: "猿の鞍",
            expression: "z = x³ − 3xy²",
            category: .polynomial,
            xRange: -10...10, yRange: -10...10,
            summary: "3方向に下がる特殊な鞍。高階の臨界点の代表例。"
        ) { x, y in x * x * x - 3 * x * y * y },

        // MARK: - 三角関数
        SurfaceFunction(
            id: "sin-cos",
            name: "sin·cos 波",
            expression: "z = sin(x)·cos(y)",
            category: .trigonometric,
            xRange: -10...10, yRange: -10...10,
            summary: "周期的な格子状の波。干渉縞の理解に。"
        ) { x, y in sin(x) * cos(y) },

        SurfaceFunction(
            id: "ripple",
            name: "中心波紋",
            expression: "z = sin(√(x² + y²))",
            category: .trigonometric,
            xRange: -10...10, yRange: -10...10,
            summary: "原点から広がる同心円状の波。水面のリップル。"
        ) { x, y in sin(sqrt(x * x + y * y)) },

        SurfaceFunction(
            id: "egg-crate",
            name: "卵パック",
            expression: "z = sin(x) + cos(y)",
            category: .trigonometric,
            xRange: -10...10, yRange: -10...10,
            summary: "規則的な凹凸が並ぶ。最適化アルゴリズムのベンチマーク関数。"
        ) { x, y in sin(x) + cos(y) },

        // MARK: - 指数・対数
        SurfaceFunction(
            id: "gaussian",
            name: "ガウス分布",
            expression: "z = exp(−(x² + y²))",
            category: .exponential,
            xRange: -10...10, yRange: -10...10,
            summary: "正規分布の2次元版。確率・統計の基礎曲面。"
        ) { x, y in exp(-(x * x + y * y)) },

        SurfaceFunction(
            id: "mexican-hat",
            name: "メキシカンハット",
            expression: "z = (1 − r²)·exp(−r²/2),  r²=x²+y²",
            category: .exponential,
            xRange: -10...10, yRange: -10...10,
            summary: "信号処理のウェーブレット。中央が盛り上がりリング状に窪む。"
        ) { x, y in
            let r2 = x * x + y * y
            return (1 - r2) * exp(-r2 / 2)
        },

        // MARK: - 特殊曲面
        SurfaceFunction(
            id: "sinc",
            name: "sinc 関数",
            expression: "z = sin(r)/r,  r=√(x²+y²)",
            category: .special,
            xRange: -10...10, yRange: -10...10,
            summary: "フーリエ解析の代表関数。中央のピークと減衰する波紋。"
        ) { x, y in
            let r = sqrt(x * x + y * y)
            return r < 1e-6 ? 1 : sin(r) / r
        },

        SurfaceFunction(
            id: "ripple-decay",
            name: "減衰波",
            expression: "z = cos(r)·exp(−r/3),  r=√(x²+y²)",
            category: .special,
            xRange: -10...10, yRange: -10...10,
            summary: "時間とともに減衰する振動。物理現象のモデルに。"
        ) { x, y in
            let r = sqrt(x * x + y * y)
            return cos(r) * exp(-r / 3)
        }
    ]

    static func byCategory() -> [(SurfaceCategory, [SurfaceFunction])] {
        SurfaceCategory.allCases.map { cat in
            (cat, all.filter { $0.category == cat })
        }
    }

    static let `default`: SurfaceFunction = all.first { $0.id == "sin-cos" } ?? all[0]
}
