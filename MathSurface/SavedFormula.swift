//
//  SavedFormula.swift
//  MathSurface
//

import Foundation
import SwiftData

@Model
final class SavedFormula {
    var id: UUID
    var name: String
    var expression: String
    var createdAt: Date
    var kind: String?  // "surface" / "line"。nil は後方互換で "surface" 扱い

    init(name: String, expression: String, kind: String = "surface", createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.expression = expression
        self.createdAt = createdAt
        self.kind = kind
    }

    var isLine: Bool {
        kind == "line"
    }

    /// SurfaceFunction に変換（パース失敗時は nil）
    func makeFunction() -> SurfaceFunction? {
        guard let evaluator = try? FormulaParser.parse(expression) else { return nil }
        let span: Double = 10
        let range: ClosedRange<Double> = -span...span
        return SurfaceFunction(
            id: "saved-\(id.uuidString)",
            name: name,
            expression: "z = \(expression)",
            category: .special,
            xRange: range,
            yRange: range,
            summary: "保存済みのカスタム関数"
        ) { x, y in
            evaluator(x, y)
        }
    }

    /// LineFunction に変換（パース失敗時は nil）
    func makeLineFunction() -> LineFunction? {
        guard let evaluator = try? LineFormulaParser.parse(expression) else { return nil }
        let span: Double = 10
        let range: ClosedRange<Double> = -span...span
        return LineFunction(
            id: "saved-line-\(id.uuidString)",
            name: name,
            expression: "y = \(expression)",
            category: .special,
            xRange: range,
            summary: "保存済みのカスタム関数"
        ) { x in
            evaluator(x)
        }
    }
}
