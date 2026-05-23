//
//  LineChartView.swift
//  MathSurface
//
//  Swift Charts による 2D 線グラフ
//

import SwiftUI
import Charts

struct LineChartView: View {
    let function: LineFunction
    var displayRadius: Double? = nil
    var showsDescription: Bool = true
    var onEdit: (() -> Void)? = nil

    @State private var zoom: CGFloat = 1.0
    @GestureState private var pinchDelta: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            chart
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(zoom * pinchDelta)
                .gesture(
                    MagnificationGesture()
                        .updating($pinchDelta) { value, state, _ in
                            state = value
                        }
                        .onEnded { value in
                            zoom = min(max(zoom * value, 0.5), 5.0)
                        }
                )
                .clipped()
                .padding(.horizontal, 14)
                .padding(.top, 8)
            if showsDescription {
                titleCard
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        switch function.kind {
        case .explicit: explicitChart
        case .implicit: implicitChart
        }
    }

    private var explicitChart: some View {
        let xRange = activeXRange
        let samples = sampledPoints(xRange: xRange, count: 400)
        let heightRange = estimatedYRange(samples)
        let clipLimit = halfExtent(xRange) * 2
        let clippedRange = clipped(heightRange, to: clipLimit)
        let wasClipped = (heightRange.lowerBound < clippedRange.lowerBound)
            || (heightRange.upperBound > clippedRange.upperBound)

        let xDomain = extendedRange(xRange, by: 1.0)
        let yDomain = extendedRange(clippedRange, by: width(clippedRange) * 0.1)

        return Chart {
            ForEach(samples, id: \.x) { p in
                if p.y.isFinite, p.y <= clippedRange.upperBound, p.y >= clippedRange.lowerBound {
                    LineMark(
                        x: .value("x", p.x),
                        y: .value("y", p.y)
                    )
                    .foregroundStyle(.indigo)
                    .interpolationMethod(.catmullRom)
                }
            }
            RuleMark(y: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
            RuleMark(x: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartXAxis { AxisMarks(position: .bottom) { _ in AxisGridLine().foregroundStyle(.secondary.opacity(0.15)); AxisTick(); AxisValueLabel() } }
        .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine().foregroundStyle(.secondary.opacity(0.15)); AxisTick(); AxisValueLabel() } }
        .overlay(alignment: .topTrailing) {
            if wasClipped {
                Label("一部省略", systemImage: "scissors")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(10)
            }
        }
    }

    private var implicitChart: some View {
        let xRange = activeXRange
        let segments = ContourBuilder.contourSegments(
            f: { x, y in function.implicitValue(x: x, y: y) },
            xRange: xRange,
            yRange: xRange,
            level: 0,
            resolution: 100
        )

        return Chart {
            ForEach(0..<segments.count, id: \.self) { i in
                let seg = segments[i]
                LineMark(
                    x: .value("x", seg.start.x),
                    y: .value("y", seg.start.y),
                    series: .value("seg", i)
                )
                .foregroundStyle(.indigo)
                LineMark(
                    x: .value("x", seg.end.x),
                    y: .value("y", seg.end.y),
                    series: .value("seg", i)
                )
                .foregroundStyle(.indigo)
            }
            RuleMark(y: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
            RuleMark(x: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
        }
        .chartXScale(domain: xRange)
        .chartYScale(domain: xRange)
        .chartXAxis { AxisMarks(position: .bottom) { _ in AxisGridLine().foregroundStyle(.secondary.opacity(0.15)); AxisTick(); AxisValueLabel() } }
        .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine().foregroundStyle(.secondary.opacity(0.15)); AxisTick(); AxisValueLabel() } }
    }

    private var titleCard: some View {
        Button {
            onEdit?()
        } label: {
            HStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(function.expression)
                        .font(.system(.title3, design: .monospaced).weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if onEdit != nil {
                    Image(systemName: "square.and.pencil")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.indigo)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(onEdit == nil)
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    // MARK: - Helpers

    private var activeXRange: ClosedRange<Double> {
        if let r = displayRadius { return -r...r }
        return function.xRange
    }

    private func sampledPoints(xRange: ClosedRange<Double>, count: Int) -> [(x: Double, y: Double)] {
        guard count > 1 else { return [] }
        let step = (xRange.upperBound - xRange.lowerBound) / Double(count - 1)
        return (0..<count).map { i in
            let x = xRange.lowerBound + Double(i) * step
            return (x, function.y(x: x))
        }
    }

    private func estimatedYRange(_ samples: [(x: Double, y: Double)]) -> ClosedRange<Double> {
        var minV = Double.infinity
        var maxV = -Double.infinity
        for p in samples where p.y.isFinite {
            if p.y < minV { minV = p.y }
            if p.y > maxV { maxV = p.y }
        }
        if !minV.isFinite || !maxV.isFinite || minV == maxV {
            return -1...1
        }
        let lower = min(minV, 0)
        let upper = max(maxV, 0)
        return lower...upper
    }

    private func halfExtent(_ range: ClosedRange<Double>) -> Double {
        max(abs(range.lowerBound), abs(range.upperBound))
    }

    private func width(_ range: ClosedRange<Double>) -> Double {
        range.upperBound - range.lowerBound
    }

    private func clipped(_ range: ClosedRange<Double>, to limit: Double) -> ClosedRange<Double> {
        let lower = max(range.lowerBound, -limit)
        let upper = min(range.upperBound, limit)
        if lower >= upper { return -limit...limit }
        return lower...upper
    }

    private func extendedRange(_ range: ClosedRange<Double>, by padding: Double) -> ClosedRange<Double> {
        (range.lowerBound - padding)...(range.upperBound + padding)
    }
}
