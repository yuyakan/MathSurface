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
            name: String(localized: "1次関数"),
            expression: "y = x",
            category: .polynomial,
            summary: String(localized: "最も基本的な比例関係。傾き1の直線。")
        ) { x in x },

        LineFunction(
            id: "line-parabola",
            name: String(localized: "放物線"),
            expression: "y = x²",
            category: .polynomial,
            summary: String(localized: "原点を頂点とする上に凸の放物線。")
        ) { x in x * x },

        LineFunction(
            id: "line-cubic",
            name: String(localized: "3次関数"),
            expression: "y = x³ − 3x",
            category: .polynomial,
            summary: String(localized: "極値を持つ3次関数。±1で極値、原点を通る。")
        ) { x in x * x * x - 3 * x },

        // MARK: - 三角関数
        LineFunction(
            id: "line-sin",
            name: String(localized: "正弦波"),
            expression: "y = sin(x)",
            category: .trigonometric,
            summary: String(localized: "周期 2π、振幅 1 の波。三角関数の基本。")
        ) { x in sin(x) },

        LineFunction(
            id: "line-tan",
            name: String(localized: "正接"),
            expression: "y = tan(x)",
            category: .trigonometric,
            summary: String(localized: "周期 π、x = π/2 + nπ で発散。")
        ) { x in tan(x) },

        // MARK: - 指数・対数
        LineFunction(
            id: "line-exp",
            name: String(localized: "指数関数"),
            expression: "y = exp(x)",
            category: .exponential,
            summary: String(localized: "ネイピア数 e を底とする指数関数。常に正。")
        ) { x in exp(x) },

        LineFunction(
            id: "line-log",
            name: String(localized: "自然対数"),
            expression: "y = log(x)",
            category: .exponential,
            summary: String(localized: "exp の逆関数。x > 0 でのみ定義。")
        ) { x in log(x) },

        // MARK: - 特殊
        LineFunction(
            id: "line-sinc",
            name: String(localized: "sinc 関数"),
            expression: "y = sin(x)/x",
            category: .special,
            summary: String(localized: "信号処理の基本関数。原点で 1、振幅は減衰。")
        ) { x in abs(x) < 1e-6 ? 1 : sin(x) / x },

        // MARK: - 陰関数（曲線）
        LineFunction(
            id: "line-circle",
            name: String(localized: "円"),
            expression: "0 = x² + y² − 9",
            category: .special,
            summary: String(localized: "半径 3 の円。x² + y² = 9 の解。")
        ) { x, y in x * x + y * y - 9 },

        LineFunction(
            id: "line-ellipse",
            name: String(localized: "楕円"),
            expression: "0 = x²/9 + y²/4 − 1",
            category: .special,
            summary: String(localized: "横半径 3、縦半径 2 の楕円。")
        ) { x, y in x * x / 9 + y * y / 4 - 1 },

        LineFunction(
            id: "line-hyperbola",
            name: String(localized: "双曲線"),
            expression: "0 = x²/4 − y² − 1",
            category: .special,
            summary: String(localized: "焦点を持つ双曲線。漸近線 y=±x/2。")
        ) { x, y in x * x / 4 - y * y - 1 },

        LineFunction(
            id: "line-lemniscate",
            name: String(localized: "レムニスケート"),
            expression: "0 = (x²+y²)² − 8(x²−y²)",
            category: .special,
            summary: String(localized: "ベルヌーイの八の字曲線。")
        ) { x, y in
            let r2 = x * x + y * y
            return r2 * r2 - 8 * (x * x - y * y)
        }
    ]

    static func byCategory() -> [(SurfaceCategory, [LineFunction])] {
        SurfaceCategory.allCases.map { cat in
            (cat, all.filter { $0.category == cat })
        }
    }

    static let `default`: LineFunction = all.first { $0.id == "line-sin" } ?? all[0]
}
