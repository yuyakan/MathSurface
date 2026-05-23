//
//  LineFunction.swift
//  MathSurface
//
//  1変数関数 y = f(x) のモデル
//

import Foundation

struct LineFunction: Identifiable, Hashable {
    let id: String
    let name: String
    let expression: String
    let category: SurfaceCategory
    let xRange: ClosedRange<Double>
    let summary: String
    private let evaluator: @Sendable (Double) -> Double

    init(
        id: String,
        name: String,
        expression: String,
        category: SurfaceCategory,
        xRange: ClosedRange<Double> = -10...10,
        summary: String = "",
        evaluator: @escaping @Sendable (Double) -> Double
    ) {
        self.id = id
        self.name = name
        self.expression = expression
        self.category = category
        self.xRange = xRange
        self.summary = summary
        self.evaluator = evaluator
    }

    func y(x: Double) -> Double {
        evaluator(x)
    }

    static func == (lhs: LineFunction, rhs: LineFunction) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
