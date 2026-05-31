//
//  SurfaceGallerySheet.swift
//  MathSurface
//
//  3D プリセットのギャラリーをシート表示（Homeタブから呼ばれる）
//

import SwiftUI

struct SurfaceGallerySheet: View {
    let onPick: (SurfaceFunction) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(PresetLibrary.byCategory(), id: \.0) { category, functions in
                        if !functions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: category.symbolName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(category.tint)
                                    Text(category.displayName)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                                ForEach(functions) { function in
                                    Button {
                                        onPick(function)
                                    } label: {
                                        SurfaceRow(function: function)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("3D 関数")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

private struct SurfaceRow: View {
    let function: SurfaceFunction
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(function.category.tint.gradient.opacity(0.85))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: function.category.symbolName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(function.name)
                    .font(.headline)
                Text(function.expression)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption.weight(.bold))
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
    }
}
