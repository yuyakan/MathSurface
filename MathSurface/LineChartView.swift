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
    var compareFunction: LineFunction? = nil
    var displayRadius: Double? = nil
    var showsDescription: Bool = true
    var onEdit: (() -> Void)? = nil
    var onCompareEdit: (() -> Void)? = nil

    @State private var zoom: CGFloat = 1.0
    @GestureState private var pinchDelta: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            chart
                .aspectRatio(1.0 / 1.25, contentMode: .fit)
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
        // 比較関数が explicit のときだけサンプリング
        let compareSamples: [(x: Double, y: Double)]
        if let comp = compareFunction, comp.kind == .explicit {
            compareSamples = sampledPointsForExplicit(f: comp, xRange: xRange, count: 400)
        } else {
            compareSamples = []
        }
        // 比較関数が implicit なら等高線を計算
        let compareSegments: [(start: (x: Double, y: Double), end: (x: Double, y: Double))]
        if let comp = compareFunction, comp.kind == .implicit {
            compareSegments = ContourBuilder.contourSegments(
                f: { x, y in comp.implicitValue(x: x, y: y) },
                xRange: xRange,
                yRange: xRange,
                level: 0,
                resolution: 100
            )
        } else {
            compareSegments = []
        }

        let allSamples = samples + compareSamples
        let heightRange = estimatedYRange(allSamples)
        // 単位比率 1:1 を保ちつつ、y軸の表示領域を x の 1.25 倍にする
        let halfY = halfExtent(xRange) * 1.25
        let clippedRange = -halfY...halfY
        let wasClipped = (heightRange.lowerBound < clippedRange.lowerBound)
            || (heightRange.upperBound > clippedRange.upperBound)

        let xDomain = extendedRange(xRange, by: 1.0)
        let yDomain = extendedRange(clippedRange, by: 1.0)

        return Chart {
            ForEach(samples, id: \.x) { p in
                if p.y.isFinite, p.y <= clippedRange.upperBound, p.y >= clippedRange.lowerBound {
                    LineMark(
                        x: .value("x", p.x),
                        y: .value("y", p.y),
                        series: .value("series", "main")
                    )
                    .foregroundStyle(.indigo)
                    .interpolationMethod(.catmullRom)
                }
            }
            if let _ = compareFunction {
                ForEach(compareSamples, id: \.x) { p in
                    if p.y.isFinite, p.y <= clippedRange.upperBound, p.y >= clippedRange.lowerBound {
                        LineMark(
                            x: .value("x", p.x),
                            y: .value("y", p.y),
                            series: .value("series", "compare")
                        )
                        .foregroundStyle(.pink)
                        .interpolationMethod(.catmullRom)
                    }
                }
                ForEach(0..<compareSegments.count, id: \.self) { i in
                    let seg = compareSegments[i]
                    LineMark(
                        x: .value("x", seg.start.x),
                        y: .value("y", seg.start.y),
                        series: .value("seg", "cmp-\(i)")
                    )
                    .foregroundStyle(.pink)
                    LineMark(
                        x: .value("x", seg.end.x),
                        y: .value("y", seg.end.y),
                        series: .value("seg", "cmp-\(i)")
                    )
                    .foregroundStyle(.pink)
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

    private func sampledPointsForExplicit(f: LineFunction, xRange: ClosedRange<Double>, count: Int) -> [(x: Double, y: Double)] {
        guard count > 1 else { return [] }
        let step = (xRange.upperBound - xRange.lowerBound) / Double(count - 1)
        return (0..<count).map { i in
            let x = xRange.lowerBound + Double(i) * step
            return (x, f.y(x: x))
        }
    }

    private var implicitChart: some View {
        let xRange = activeXRange
        let halfY = halfExtent(xRange) * 1.25
        let yRange: ClosedRange<Double> = -halfY...halfY
        let mainSegments = ContourBuilder.contourSegments(
            f: { x, y in function.implicitValue(x: x, y: y) },
            xRange: xRange,
            yRange: yRange,
            level: 0,
            resolution: 100
        )

        // 比較関数: implicit ならその場で等高線、explicit ならサンプリングで折れ線
        let compareSegments: [(start: (x: Double, y: Double), end: (x: Double, y: Double))]
        let comparePolyline: [(x: Double, y: Double)]
        if let comp = compareFunction {
            switch comp.kind {
            case .implicit:
                compareSegments = ContourBuilder.contourSegments(
                    f: { x, y in comp.implicitValue(x: x, y: y) },
                    xRange: xRange,
                    yRange: yRange,
                    level: 0,
                    resolution: 100
                )
                comparePolyline = []
            case .explicit:
                compareSegments = []
                comparePolyline = sampledPointsForExplicit(f: comp, xRange: xRange, count: 400)
            }
        } else {
            compareSegments = []
            comparePolyline = []
        }

        return Chart {
            ForEach(0..<mainSegments.count, id: \.self) { i in
                let seg = mainSegments[i]
                LineMark(
                    x: .value("x", seg.start.x),
                    y: .value("y", seg.start.y),
                    series: .value("seg", "main-\(i)")
                )
                .foregroundStyle(.indigo)
                LineMark(
                    x: .value("x", seg.end.x),
                    y: .value("y", seg.end.y),
                    series: .value("seg", "main-\(i)")
                )
                .foregroundStyle(.indigo)
            }
            ForEach(0..<compareSegments.count, id: \.self) { i in
                let seg = compareSegments[i]
                LineMark(
                    x: .value("x", seg.start.x),
                    y: .value("y", seg.start.y),
                    series: .value("seg", "cmp-\(i)")
                )
                .foregroundStyle(.pink)
                LineMark(
                    x: .value("x", seg.end.x),
                    y: .value("y", seg.end.y),
                    series: .value("seg", "cmp-\(i)")
                )
                .foregroundStyle(.pink)
            }
            ForEach(comparePolyline, id: \.x) { p in
                if p.y.isFinite {
                    LineMark(
                        x: .value("x", p.x),
                        y: .value("y", p.y),
                        series: .value("series", "cmp-line")
                    )
                    .foregroundStyle(.pink)
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
        .chartXScale(domain: xRange)
        .chartYScale(domain: yRange)
        .chartXAxis { AxisMarks(position: .bottom) { _ in AxisGridLine().foregroundStyle(.secondary.opacity(0.15)); AxisTick(); AxisValueLabel() } }
        .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine().foregroundStyle(.secondary.opacity(0.15)); AxisTick(); AxisValueLabel() } }
    }

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { onEdit?() } label: {
                expressionRow(text: function.expression, accent: .indigo, showsPencil: onEdit != nil)
            }
            .buttonStyle(.plain)
            .disabled(onEdit == nil)

            if let compareFunction {
                Button { onCompareEdit?() } label: {
                    expressionRow(text: compareFunction.expression, accent: .pink, showsPencil: onCompareEdit != nil)
                }
                .buttonStyle(.plain)
                .disabled(onCompareEdit == nil)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func expressionRow(text: String, accent: Color, showsPencil: Bool) -> some View {
        HStack(spacing: 10) {
            Circle().fill(accent).frame(width: 8, height: 8)
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(.system(.title3, design: .monospaced).weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if showsPencil {
                Image(systemName: "square.and.pencil")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(accent)
            }
        }
        .contentShape(Rectangle())
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
