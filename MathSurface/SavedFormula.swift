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

    init(name: String, expression: String, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.expression = expression
        self.createdAt = createdAt
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
}
