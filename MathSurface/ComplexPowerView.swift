//
//  ComplexPowerView.swift
//  MathSurface
//
//  冪乗サブモード: z^k の軌跡 + 1のn乗根の正多角形
//

import SwiftUI

struct ComplexPowerView: View {
    @Environment(SurfaceStore.self) private var store

    private var radius: Double { store.complexRadius }

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 12) {
            ComplexPlaneView(
                radius: radius,
                points: allPoints,
                vectors: vectors,
                showsUnitCircle: true
            )

            descriptionBanner
            zSliderCard
            nSliderCard
            polarReadout
            ComplexRadiusSlider()
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var descriptionBanner: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundStyle(.indigo)
            Text("z の累乗 z¹, z², ..., zⁿ を青点で表示。緑点は 1 のn乗根（n≥2）。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var zSliderCard: some View {
        @Bindable var store = store
        return VStack(spacing: 6) {
            HStack {
                Text("z")
                    .font(.callout.weight(.semibold).monospaced())
                    .foregroundStyle(.blue)
                Spacer()
                Button("z = 1") {
                    store.complexZ = Complex(re: 1, im: 0)
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(.indigo)
            }
            HStack(spacing: 8) {
                Text("Re").font(.caption2).foregroundStyle(.secondary).frame(width: 24)
                Slider(value: $store.complexZ.re, in: -2...2, step: 0.05).tint(.blue)
            }
            HStack(spacing: 8) {
                Text("Im").font(.caption2).foregroundStyle(.secondary).frame(width: 24)
                Slider(value: $store.complexZ.im, in: -2...2, step: 0.05).tint(.blue)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var nSliderCard: some View {
        @Bindable var store = store
        let nBinding = Binding<Double>(
            get: { Double(store.complexN) },
            set: { store.complexN = Int($0) }
        )
        return VStack(spacing: 6) {
            HStack {
                Text("n")
                    .font(.callout.weight(.semibold).monospaced())
                    .foregroundStyle(.purple)
                Spacer()
                Text("\(store.complexN)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: nBinding, in: 1...10, step: 1).tint(.purple)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var polarReadout: some View {
        let z = store.complexZ
        let r = z.magnitude
        let theta = z.argument * 180 / .pi
        return HStack {
            Text(String(format: "|z| = %.2f", r))
                .font(.caption.monospacedDigit())
            Spacer()
            Text(String(format: "arg(z) = %.1f°", theta))
                .font(.caption.monospacedDigit())
            Spacer()
            Text("z^\(store.complexN) = \(z.power(store.complexN).description)")
                .font(.caption.monospacedDigit())
                .lineLimit(1)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
    }

    /// z^k 軌跡 + 1の n乗根
    private var allPoints: [ComplexPlanePoint] {
        var pts: [ComplexPlanePoint] = []
        let n = store.complexN
        let z = store.complexZ

        // z^k for k=1..|n| を青系
        if n != 0 {
            let absN = abs(n)
            for k in 1...absN {
                let zk = n > 0 ? z.power(k) : z.power(-k)
                pts.append(ComplexPlanePoint(
                    z: zk,
                    color: .blue,
                    label: absN <= 5 ? "z^\(n > 0 ? k : -k)" : nil
                ))
            }
        }

        // 1の n乗根（n≥2 のとき、単位円上の n等分点）
        if n >= 2 {
            for k in 0..<n {
                let theta = 2 * Double.pi * Double(k) / Double(n)
                pts.append(ComplexPlanePoint(
                    z: Complex(re: cos(theta), im: sin(theta)),
                    color: .green,
                    label: nil
                ))
            }
        }

        return pts
    }

    private var vectors: [ComplexPlaneVector] {
        guard store.complexN != 0 else { return [] }
        return [
            ComplexPlaneVector(from: .zero, to: store.complexZ, color: .blue, style: .solid)
        ]
    }
}
