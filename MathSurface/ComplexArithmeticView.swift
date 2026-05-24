//
//  ComplexArithmeticView.swift
//  MathSurface
//
//  演算サブモード: z, w, z+w, z*w
//

import SwiftUI

struct ComplexArithmeticView: View {
    @Environment(SurfaceStore.self) private var store

    private var radius: Double { store.complexRadius }
    private var sliderRange: ClosedRange<Double> { -radius...radius }

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 12) {
            ComplexPlaneView(
                radius: radius,
                points: points,
                vectors: vectors
            )

            sliderCard(title: "z", re: $store.complexZ.re, im: $store.complexZ.im, color: .blue)
            sliderCard(title: "w", re: $store.complexW.re, im: $store.complexW.im, color: .green)
            resultRow
            ComplexRadiusSlider()
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var points: [ComplexPlanePoint] {
        let z = store.complexZ
        let w = store.complexW
        return [
            ComplexPlanePoint(z: z, color: .blue, label: "z"),
            ComplexPlanePoint(z: w, color: .green, label: "w"),
            ComplexPlanePoint(z: z + w, color: .red, label: "z+w"),
            ComplexPlanePoint(z: z * w, color: .orange, label: "z×w")
        ]
    }

    private var vectors: [ComplexPlaneVector] {
        let z = store.complexZ
        let w = store.complexW
        let sum = z + w
        return [
            ComplexPlaneVector(from: .zero, to: z, color: .blue, style: .solid),
            ComplexPlaneVector(from: .zero, to: w, color: .green, style: .solid),
            ComplexPlaneVector(from: .zero, to: sum, color: .red, style: .solid),
            ComplexPlaneVector(from: .zero, to: z * w, color: .orange, style: .solid),
            // 平行四辺形の補助線
            ComplexPlaneVector(from: z, to: sum, color: .red.opacity(0.5), style: .dashed),
            ComplexPlaneVector(from: w, to: sum, color: .red.opacity(0.5), style: .dashed)
        ]
    }

    private func sliderCard(title: String, re: Binding<Double>, im: Binding<Double>, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.callout.weight(.semibold).monospaced())
                    .foregroundStyle(color)
                Spacer()
                Text(String(format: "%.1f %@ %.1fi", re.wrappedValue, im.wrappedValue >= 0 ? "+" : "−", abs(im.wrappedValue)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Text("Re").font(.caption2).foregroundStyle(.secondary).frame(width: 24)
                Slider(value: re, in: sliderRange, step: 0.1).tint(color)
            }
            HStack(spacing: 8) {
                Text("Im").font(.caption2).foregroundStyle(.secondary).frame(width: 24)
                Slider(value: im, in: sliderRange, step: 0.1).tint(color)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var resultRow: some View {
        let z = store.complexZ
        let w = store.complexW
        return HStack(spacing: 12) {
            Label(z + w == .zero ? "z + w = 0" : "z + w = \((z + w).description)", systemImage: "plus")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            Spacer()
            Label("z × w = \((z * w).description)", systemImage: "multiply")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 10)
    }
}
