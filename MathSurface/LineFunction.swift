//
//  LineFunction.swift
//  MathSurface
//
//  1変数関数 y = f(x) のモデル
//

import Foundation

enum LineFunctionKind: Hashable {
    case explicit  // y = f(x)
    case implicit  // 0 = F(x, y)
}

struct LineFunction: Identifiable, Hashable {
    let id: String
    let name: String
    let expression: String
    let category: SurfaceCategory
    let xRange: ClosedRange<Double>
    let summary: String
    let kind: LineFunctionKind
    private let evaluator1D: (@Sendable (Double) -> Double)?
    private let evaluator2D: (@Sendable (Double, Double) -> Double)?

    /// 陽関数 y = f(x)
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
        self.kind = .explicit
        self.evaluator1D = evaluator
        self.evaluator2D = nil
    }

    /// 陰関数 0 = F(x, y)
    init(
        id: String,
        name: String,
        expression: String,
        category: SurfaceCategory,
        xRange: ClosedRange<Double> = -10...10,
        summary: String = "",
        implicitEvaluator: @escaping @Sendable (Double, Double) -> Double
    ) {
        self.id = id
        self.name = name
        self.expression = expression
        self.category = category
        self.xRange = xRange
        self.summary = summary
        self.kind = .implicit
        self.evaluator1D = nil
        self.evaluator2D = implicitEvaluator
    }

    /// 陽関数として評価。陰関数の場合は nan を返す。
    func y(x: Double) -> Double {
        evaluator1D?(x) ?? .nan
    }

    /// 陰関数として評価。陽関数の場合は y - f(x) を返す。
    func implicitValue(x: Double, y: Double) -> Double {
        if let e = evaluator2D { return e(x, y) }
        if let e = evaluator1D { return y - e(x) }
        return .nan
    }

    static func == (lhs: LineFunction, rhs: LineFunction) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
