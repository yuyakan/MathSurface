//
//  ComplexRadiusSlider.swift
//  MathSurface
//
//  複素平面の表示半径を調整するスライダー（複素数タブ各サブモード共通）
//

import SwiftUI

struct ComplexRadiusSlider: View {
    @Environment(SurfaceStore.self) private var store

    var body: some View {
        @Bindable var store = store
        HStack(spacing: 10) {
            Label("表示範囲", systemImage: "ruler")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.indigo)
            Slider(value: $store.complexRadius, in: 1...20, step: 0.5)
                .tint(.indigo)
            Text(String(format: "±%.1f", store.complexRadius))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
