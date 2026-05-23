//
//  SurfaceFunction.swift
//  MathSurface
//

import Foundation
import SwiftUI

enum SurfaceCategory: String, CaseIterable, Identifiable {
    case polynomial = "多項式"
    case trigonometric = "三角関数"
    case exponential = "指数・対数"
    case special = "特殊曲面"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .polynomial: "function"
        case .trigonometric: "waveform.path"
        case .exponential: "chart.line.uptrend.xyaxis"
        case .special: "globe.asia.australia"
        }
    }

    var tint: Color {
        switch self {
        case .polynomial: .blue
        case .trigonometric: .pink
        case .exponential: .orange
        case .special: .purple
        }
    }
}

struct SurfaceFunction: Identifiable, Hashable {
    let id: String
    let name: String
    let expression: String
    let category: SurfaceCategory
    let xRange: ClosedRange<Double>
    let yRange: ClosedRange<Double>
    let summary: String
    private let evaluator: @Sendable (Double, Double) -> Double

    init(
        id: String,
        name: String,
        expression: String,
        category: SurfaceCategory,
        xRange: ClosedRange<Double> = -10...10,
        yRange: ClosedRange<Double> = -10...10,
        summary: String,
        evaluator: @escaping @Sendable (Double, Double) -> Double
    ) {
        self.id = id
        self.name = name
        self.expression = expression
        self.category = category
        self.xRange = xRange
        self.yRange = yRange
        self.summary = summary
        self.evaluator = evaluator
    }

    func z(x: Double, y: Double) -> Double {
        evaluator(x, y)
    }

    static func == (lhs: SurfaceFunction, rhs: SurfaceFunction) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
