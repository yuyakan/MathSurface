//
//  SurfaceView.swift
//  MathSurface
//

import SwiftUI
import Charts
import Spatial

struct SurfaceView: View {
    let function: SurfaceFunction
    var compareFunction: SurfaceFunction? = nil
    var showsDescription: Bool = true
    var displayRadius: Double? = nil  // 指定があれば function の range を上書き
    var onEdit: (() -> Void)? = nil   // titleCard メイン式タップ時
    var onCompareEdit: (() -> Void)? = nil  // titleCard 比較式タップ時

    @State private var pose: Chart3DPose = Chart3DPose(
        azimuth: .degrees(30),
        inclination: .degrees(20)
    )
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
            if showsDescription {
                titleCard
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut) {
                        pose = Chart3DPose(
                            azimuth: .degrees(30),
                            inclination: .degrees(20)
                        )
                        zoom = 1.0
                    }
                } label: {
                    Label("視点をリセット", systemImage: "arrow.counterclockwise")
                }
            }
        }
    }

    private var chart: some View {
        // Apple Chart3D の軸対応:
        //   x軸 = 横、y軸 = 高さ(クロージャ戻り値)、z軸 = 奥行き
        // SurfacePlot のクロージャは (x, z) -> y
        let xRange = activeXRange
        let yRange = activeYRange
        let rawHeightRange = estimatedHeightRange(xRange: xRange, yRange: yRange)
        // クリップ撤廃: 関数の実値域をそのまま使う
        let clippedHeightRange = rawHeightRange
        let wasClipped = false

        // 軸の端の数値ラベルがビュー境界に隠れないよう、domain を少し広げる
        let xDomain = extendedRange(xRange, by: 1.0)
        let zDomain = extendedRange(yRange, by: 1.0)
        let yDomain = extendedRange(clippedHeightRange, by: width(clippedHeightRange) * 0.1)

        // xy 軸の最大幅を基準に物理長さを比例配分
        let maxXYWidth = max(width(xDomain), width(zDomain))
        let xRangeCG = proportionalRange(width: width(xDomain), maxWidth: maxXYWidth)
        let zRangeCG = proportionalRange(width: width(zDomain), maxWidth: maxXYWidth)
        // y軸: 値域が xy より広い場合だけ、xy と同じ物理長に圧縮
        let yRangeCG: ClosedRange<CGFloat>
        if width(yDomain) <= maxXYWidth {
            yRangeCG = proportionalRange(width: width(yDomain), maxWidth: maxXYWidth)
        } else {
            yRangeCG = -0.5...0.5
        }

        return Chart3D {
            SurfacePlot(
                x: "x",
                y: "z",
                z: "y"
            ) { x, z in
                // 範囲チェックなし: Chart3D が domain で領域を制御
                return function.z(x: x, y: z)
            }
            .foregroundStyle(.heightBased(surfaceGradient, yRange: CGFloat(clippedHeightRange.lowerBound)...CGFloat(clippedHeightRange.upperBound)))

            if let compareFunction {
                SurfacePlot(
                    x: "cx",
                    y: "cz",
                    z: "cy"
                ) { x, z in
                    let v = compareFunction.z(x: x, y: z)
                    return v.isFinite ? v : .nan
                }
                .foregroundStyle(Color.pink.opacity(0.55))
            }
        }
        .chartXScale(domain: xDomain, range: xRangeCG)
        .chartYScale(domain: yDomain, range: yRangeCG)
        .chartZScale(domain: zDomain, range: zRangeCG)
        .chartXAxisLabel("x")
        .chartYAxisLabel("z")
        .chartZAxisLabel("y")
        .chart3DPose($pose)
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

    private var activeXRange: ClosedRange<Double> {
        if let r = displayRadius { return -r...r }
        return function.xRange
    }

    private var activeYRange: ClosedRange<Double> {
        if let r = displayRadius { return -r...r }
        return function.yRange
    }

    private func halfExtent(_ range: ClosedRange<Double>) -> Double {
        max(abs(range.lowerBound), abs(range.upperBound))
    }

    private func clipped(_ range: ClosedRange<Double>, to limit: Double) -> ClosedRange<Double> {
        let lower = max(range.lowerBound, -limit)
        let upper = min(range.upperBound, limit)
        if lower >= upper {
            return -limit...limit
        }
        return lower...upper
    }

    /// 範囲の両端に余白を追加して返す（描画範囲外でも軸が見えるように）
    private func extendedRange(_ range: ClosedRange<Double>, by padding: Double) -> ClosedRange<Double> {
        (range.lowerBound - padding)...(range.upperBound + padding)
    }

    // MARK: - Helpers

    private func width(_ range: ClosedRange<Double>) -> Double {
        range.upperBound - range.lowerBound
    }

    /// サーフェスの高さベースグラデーション（ダーク背景に映える配色、明度抑え)
    private var surfaceGradient: Gradient {
        Gradient(colors: [
            Color(red: 0.42, green: 0.25, blue: 0.78),
            Color(red: 0.20, green: 0.68, blue: 0.85),
            Color(red: 0.36, green: 0.78, blue: 0.20),
            Color(red: 0.85, green: 0.78, blue: 0.20),
            Color(red: 0.85, green: 0.32, blue: 0.55),
            Color(red: 0.85, green: 0.78, blue: 0.78)
        ])
    }

    private func proportionalRange(width: Double, maxWidth: Double) -> ClosedRange<CGFloat> {
        guard maxWidth > 0 else { return -0.5...0.5 }
        // 0.95 倍で一回り内側に縮め、Chart3D 領域の端で見切れないようにする
        let half = CGFloat(width / maxWidth) / 2 * 0.95
        return -half...half
    }

    /// 関数の値域(高さ)を粗くサンプリングして推定
    private func estimatedHeightRange(xRange: ClosedRange<Double>, yRange: ClosedRange<Double>) -> ClosedRange<Double> {
        let steps = 64
        var minV = Double.infinity
        var maxV = -Double.infinity
        let dx = (xRange.upperBound - xRange.lowerBound) / Double(steps)
        let dy = (yRange.upperBound - yRange.lowerBound) / Double(steps)
        for i in 0...steps {
            for j in 0...steps {
                let x = xRange.lowerBound + Double(i) * dx
                let y = yRange.lowerBound + Double(j) * dy
                let v = function.z(x: x, y: y)
                if v.isFinite {
                    if v < minV { minV = v }
                    if v > maxV { maxV = v }
                }
                if let cmp = compareFunction {
                    let cv = cmp.z(x: x, y: y)
                    if cv.isFinite {
                        if cv < minV { minV = cv }
                        if cv > maxV { maxV = cv }
                    }
                }
            }
        }
        if !minV.isFinite || !maxV.isFinite || minV == maxV {
            return -1...1
        }
        let lower = min(minV, 0)
        let upper = max(maxV, 0)
        return lower...upper
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
}

#Preview {
    NavigationStack {
        SurfaceView(function: PresetLibrary.default)
    }
}
