//
//  ProbabilityTab.swift
//  MathSurface
//
//  確率分布タブ（二項分布、正規分布）
//

import SwiftUI
import Charts

enum ProbabilityDistribution: String, CaseIterable, Identifiable {
    case binomial = "二項分布"
    case normal = "正規分布"
    var id: String { rawValue }
}

struct ProbabilityTab: View {
    @State private var distribution: ProbabilityDistribution = .binomial

    // 二項分布
    @State private var binomialN: Double = 10
    @State private var binomialP: Double = 0.5

    // 正規分布
    @State private var normalMu: Double = 0
    @State private var normalSigma: Double = 1

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 8) {
                    Picker("分布", selection: $distribution) {
                        ForEach(ProbabilityDistribution.allCases) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                    ScrollView {
                        VStack(spacing: 12) {
                            chart
                                .frame(height: 360)
                                .padding(.horizontal, 14)
                            descriptionCard
                            parameterCards
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chart: some View {
        switch distribution {
        case .binomial: binomialChart
        case .normal: normalChart
        }
    }

    private var binomialChart: some View {
        let n = Int(binomialN)
        let p = binomialP
        let bars = (0...n).map { k in
            (k: k, prob: binomialPMF(n: n, k: k, p: p))
        }
        return Chart {
            ForEach(bars, id: \.k) { b in
                BarMark(
                    x: .value("k", b.k),
                    y: .value("確率", b.prob)
                )
                .foregroundStyle(.indigo)
            }
        }
        .chartXScale(domain: -0.5...(Double(n) + 0.5))
        .chartXAxisLabel("成功回数 k", position: .bottom)
        .chartYAxisLabel("確率", position: .leading)
    }

    private var normalChart: some View {
        let mu = normalMu
        let sigma = normalSigma
        // x軸範囲は μ, σ に依存せず固定（μ が動いても目盛が切り替わらない）
        let xMin: Double = -15
        let xMax: Double = 15
        let steps = 300
        let samples = (0...steps).map { i -> (x: Double, y: Double) in
            let x = xMin + (xMax - xMin) * Double(i) / Double(steps)
            return (x, normalPDF(x: x, mu: mu, sigma: sigma))
        }
        return Chart {
            ForEach(samples, id: \.x) { s in
                AreaMark(
                    x: .value("x", s.x),
                    y: .value("密度", s.y)
                )
                .foregroundStyle(Color.indigo.opacity(0.25))
                LineMark(
                    x: .value("x", s.x),
                    y: .value("密度", s.y)
                )
                .foregroundStyle(.indigo)
                .interpolationMethod(.catmullRom)
            }
            RuleMark(x: .value("μ", mu))
                .foregroundStyle(.pink.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .chartXScale(domain: xMin...xMax)
        .chartXAxisLabel("x", position: .bottom)
        .chartYAxisLabel("密度", position: .leading)
    }

    // MARK: - Description

    private var descriptionCard: some View {
        let text: String
        switch distribution {
        case .binomial:
            text = "二項分布 B(n, p)：n 回の独立試行で、確率 p で成功するときの成功回数 k の確率分布。"
        case .normal:
            text = "正規分布 N(μ, σ²)：平均 μ、標準偏差 σ の連続分布。釣鐘型の曲線。"
        }
        return HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle").foregroundStyle(.indigo)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 14)
    }

    // MARK: - Parameters

    @ViewBuilder
    private var parameterCards: some View {
        switch distribution {
        case .binomial:
            VStack(spacing: 10) {
                sliderRow(label: "n（試行回数）", value: $binomialN, range: 1...50, step: 1, format: "%.0f")
                sliderRow(label: "p（成功確率）", value: $binomialP, range: 0...1, step: 0.01, format: "%.2f")
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        case .normal:
            VStack(spacing: 10) {
                sliderRow(label: "μ（平均）", value: $normalMu, range: -5...5, step: 0.1, format: "%.1f")
                sliderRow(label: "σ（標準偏差）", value: $normalSigma, range: 0.1...5, step: 0.1, format: "%.1f")
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.indigo)
                .frame(width: 110, alignment: .leading)
            Slider(value: value, in: range, step: step).tint(.indigo)
            Text(String(format: format, value.wrappedValue))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Math

    private func binomialPMF(n: Int, k: Int, p: Double) -> Double {
        guard k >= 0, k <= n, p >= 0, p <= 1 else { return 0 }
        return binomialCoefficient(n: n, k: k) * pow(p, Double(k)) * pow(1 - p, Double(n - k))
    }

    private func binomialCoefficient(n: Int, k: Int) -> Double {
        if k < 0 || k > n { return 0 }
        let kk = min(k, n - k)
        var result: Double = 1
        for i in 0..<kk {
            result = result * Double(n - i) / Double(i + 1)
        }
        return result
    }

    private func normalPDF(x: Double, mu: Double, sigma: Double) -> Double {
        let coef = 1.0 / (sigma * sqrt(2 * .pi))
        let exponent = -((x - mu) * (x - mu)) / (2 * sigma * sigma)
        return coef * exp(exponent)
    }
}
