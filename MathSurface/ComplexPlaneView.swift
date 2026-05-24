//
//  ComplexPlaneView.swift
//  MathSurface
//
//  複素平面の汎用描画ビュー（Re/Im、1:1）
//

import SwiftUI
import Charts

struct ComplexPlanePoint: Identifiable {
    let id = UUID()
    let z: Complex
    let color: Color
    let label: String?
}

struct ComplexPlaneVector: Identifiable {
    let id = UUID()
    let from: Complex
    let to: Complex
    let color: Color
    let style: VectorStyle

    enum VectorStyle { case solid, dashed }
}

struct ComplexPlaneContour: Identifiable {
    let id = UUID()
    let segments: [(start: (x: Double, y: Double), end: (x: Double, y: Double))]
    let color: Color
}

struct ComplexPlaneView: View {
    var radius: Double = 5
    var points: [ComplexPlanePoint] = []
    var vectors: [ComplexPlaneVector] = []
    var contours: [ComplexPlaneContour] = []
    var showsUnitCircle: Bool = false

    @State private var zoom: CGFloat = 1.0
    @GestureState private var pinchDelta: CGFloat = 1.0

    var body: some View {
        chart
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(zoom * pinchDelta)
            .gesture(
                MagnificationGesture()
                    .updating($pinchDelta) { value, state, _ in state = value }
                    .onEnded { value in zoom = min(max(zoom * value, 0.5), 5.0) }
            )
            .clipped()
            .padding(.horizontal, 14)
            .padding(.top, 8)
    }

    private var chart: some View {
        let r = radius
        return Chart {
            // 単位円（参照）
            if showsUnitCircle {
                let n = 80
                ForEach(0..<n, id: \.self) { i in
                    let t = 2 * Double.pi * Double(i) / Double(n)
                    let t2 = 2 * Double.pi * Double(i + 1) / Double(n)
                    LineMark(
                        x: .value("x", cos(t)),
                        y: .value("y", sin(t)),
                        series: .value("unit", "u\(i)")
                    )
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    LineMark(
                        x: .value("x", cos(t2)),
                        y: .value("y", sin(t2)),
                        series: .value("unit", "u\(i)")
                    )
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                }
            }

            // 等高線（軌跡）
            ForEach(contours) { contour in
                ForEach(0..<contour.segments.count, id: \.self) { i in
                    let s = contour.segments[i]
                    LineMark(
                        x: .value("x", s.start.x),
                        y: .value("y", s.start.y),
                        series: .value("c", "\(contour.id)-\(i)")
                    )
                    .foregroundStyle(contour.color)
                    LineMark(
                        x: .value("x", s.end.x),
                        y: .value("y", s.end.y),
                        series: .value("c", "\(contour.id)-\(i)")
                    )
                    .foregroundStyle(contour.color)
                }
            }

            // ベクトル（線分）
            ForEach(vectors) { vec in
                LineMark(
                    x: .value("x", vec.from.re),
                    y: .value("y", vec.from.im),
                    series: .value("v", vec.id.uuidString)
                )
                .foregroundStyle(vec.color)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: vec.style == .dashed ? [5, 4] : []))
                LineMark(
                    x: .value("x", vec.to.re),
                    y: .value("y", vec.to.im),
                    series: .value("v", vec.id.uuidString)
                )
                .foregroundStyle(vec.color)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: vec.style == .dashed ? [5, 4] : []))
            }

            // 点
            ForEach(points) { p in
                PointMark(
                    x: .value("x", p.z.re),
                    y: .value("y", p.z.im)
                )
                .foregroundStyle(p.color)
                .symbolSize(100)
                .annotation(position: .top, alignment: .center) {
                    if let label = p.label {
                        Text(label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(p.color)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(.systemBackground).opacity(0.85))
                                    .overlay(Capsule().stroke(p.color.opacity(0.4), lineWidth: 0.5))
                            )
                    }
                }
            }

            // 軸線
            RuleMark(y: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
            RuleMark(x: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
        }
        .chartXScale(domain: -r...r)
        .chartYScale(domain: -r...r)
        .chartXAxisLabel("Re", position: .bottom)
        .chartYAxisLabel("Im", position: .leading)
    }
}
