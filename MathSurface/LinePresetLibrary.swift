//
//  LinePresetLibrary.swift
//  MathSurface
//

import Foundation

enum LinePresetLibrary {
    static let all: [LineFunction] = [
        // MARK: - 多項式
        LineFunction(
            id: "line-linear",
            name: "1次関数",
            expression: "y = x",
            category: .polynomial,
            summary: "最も基本的な比例関係。傾き1の直線。"
        ) { x in x },

        LineFunction(
            id: "line-parabola",
            name: "放物線",
            expression: "y = x²",
            category: .polynomial,
            summary: "原点を頂点とする上に凸の放物線。"
        ) { x in x * x },

        LineFunction(
            id: "line-cubic",
            name: "3次関数",
            expression: "y = x³ − 3x",
            category: .polynomial,
            summary: "極値を持つ3次関数。±1で極値、原点を通る。"
        ) { x in x * x * x - 3 * x },

        // MARK: - 三角関数
        LineFunction(
            id: "line-sin",
            name: "正弦波",
            expression: "y = sin(x)",
            category: .trigonometric,
            summary: "周期 2π、振幅 1 の波。三角関数の基本。"
        ) { x in sin(x) },

        LineFunction(
            id: "line-tan",
            name: "正接",
            expression: "y = tan(x)",
            category: .trigonometric,
            summary: "周期 π、x = π/2 + nπ で発散。"
        ) { x in tan(x) },

        // MARK: - 指数・対数
        LineFunction(
            id: "line-exp",
            name: "指数関数",
            expression: "y = exp(x)",
            category: .exponential,
            summary: "ネイピア数 e を底とする指数関数。常に正。"
        ) { x in exp(x) },

        LineFunction(
            id: "line-log",
            name: "自然対数",
            expression: "y = log(x)",
            category: .exponential,
            summary: "exp の逆関数。x > 0 でのみ定義。"
        ) { x in log(x) },

        // MARK: - 特殊
        LineFunction(
            id: "line-sinc",
            name: "sinc 関数",
            expression: "y = sin(x)/x",
            category: .special,
            summary: "信号処理の基本関数。原点で 1、振幅は減衰。"
        ) { x in abs(x) < 1e-6 ? 1 : sin(x) / x }
    ]

    static func byCategory() -> [(SurfaceCategory, [LineFunction])] {
        SurfaceCategory.allCases.map { cat in
            (cat, all.filter { $0.category == cat })
        }
    }

    static let `default`: LineFunction = all.first { $0.id == "line-sin" } ?? all[0]
}
