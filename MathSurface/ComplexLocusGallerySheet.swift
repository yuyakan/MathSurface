//
//  ComplexLocusGallerySheet.swift
//  MathSurface
//
//  軌跡モードの式プリセット一覧シート
//

import SwiftUI

struct ComplexLocusPreset: Identifiable {
    let id = UUID()
    let name: String
    let formula: String
    let summary: String
}

enum ComplexLocusPresetLibrary {
    static let categories: [(name: String, presets: [ComplexLocusPreset])] = [
        ("円", [
            ComplexLocusPreset(name: "単位円", formula: "|z| = 1", summary: "原点中心、半径1"),
            ComplexLocusPreset(name: "中心α・半径r", formula: "|z - (1+i)| = 2", summary: "中心 (1,1)、半径 2"),
            ComplexLocusPreset(name: "アポロニウスの円", formula: "|z - 1| = 2|z + 1|", summary: "2点から距離の比が一定"),
            ComplexLocusPreset(name: "直径の円", formula: "Re((z-1)/(z+1)) = 0", summary: "1 と −1 を直径とする円"),
        ]),
        ("直線", [
            ComplexLocusPreset(name: "実軸", formula: "Im(z) = 0", summary: "y = 0"),
            ComplexLocusPreset(name: "虚軸", formula: "Re(z) = 0", summary: "x = 0"),
            ComplexLocusPreset(name: "y = x", formula: "Re(z) = Im(z)", summary: "45°の直線"),
            ComplexLocusPreset(name: "垂直二等分線", formula: "|z - 1| = |z + i|", summary: "2点 1 と −i から等距離"),
            ComplexLocusPreset(name: "水平線", formula: "Im(z) = 2", summary: "y = 2 の直線"),
        ]),
        ("半直線・偏角", [
            ComplexLocusPreset(name: "原点から π/4", formula: "arg(z) = pi/4", summary: "偏角 45°の半直線"),
            ComplexLocusPreset(name: "1から π/4", formula: "arg(z - 1) = pi/4", summary: "(1, 0) から 45°方向"),
            ComplexLocusPreset(name: "1からπ/2", formula: "arg(z - 1) = pi/2", summary: "(1, 0) から真上"),
        ]),
        ("特殊曲線", [
            ComplexLocusPreset(name: "楕円 (焦点 ±1)", formula: "|z - 1| + |z + 1| = 4", summary: "焦点 ±1 で長軸 4"),
            ComplexLocusPreset(name: "双曲線 (焦点 ±2)", formula: "|z - 2| - |z + 2| = 2", summary: "焦点 ±2 で差が 2"),
            ComplexLocusPreset(name: "|z|² = 4", formula: "z * conj(z) = 4", summary: "半径 2 の円（別表記）"),
            ComplexLocusPreset(name: "レムニスケート風", formula: "|z - 1| * |z + 1| = 1", summary: "2点からの距離の積"),
        ]),
        ("発展", [
            ComplexLocusPreset(name: "実部一定", formula: "Re(z^2) = 1", summary: "双曲線"),
            ComplexLocusPreset(name: "虚部一定", formula: "Im(z^2) = 2", summary: "双曲線"),
        ])
    ]
}

struct ComplexLocusGallerySheet: View {
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<ComplexLocusPresetLibrary.categories.count, id: \.self) { i in
                        let cat = ComplexLocusPresetLibrary.categories[i]
                        VStack(alignment: .leading, spacing: 8) {
                            Text(cat.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.indigo)
                                .padding(.horizontal, 4)
                            ForEach(cat.presets) { preset in
                                Button {
                                    onPick(preset.formula)
                                    dismiss()
                                } label: {
                                    row(for: preset)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("軌跡プリセット")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func row(for preset: ComplexLocusPreset) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.85))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "circle.hexagongrid")
                        .foregroundStyle(.white)
                        .font(.callout.weight(.semibold))
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name)
                    .font(.headline)
                Text(preset.formula)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(preset.summary)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption.weight(.bold))
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
    }
}
