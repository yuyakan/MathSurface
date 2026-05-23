//
//  GalleryTab.swift
//  MathSurface
//

import SwiftUI

struct GalleryTab: View {
    @Environment(SurfaceStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(PresetLibrary.byCategory(), id: \.0) { category, functions in
                        VStack(alignment: .leading, spacing: 8) {
                            categoryHeader(category)
                            VStack(spacing: 8) {
                                ForEach(functions) { function in
                                    Button {
                                        store.select(function)
                                    } label: {
                                        functionRow(function)
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
            .scrollContentBackground(.hidden)
            .background(backgroundGradient)
            .navigationTitle("ギャラリー")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func categoryHeader(_ category: SurfaceCategory) -> some View {
        HStack(spacing: 8) {
            Image(systemName: category.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(category.tint)
            Text(category.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private func functionRow(_ function: SurfaceFunction) -> some View {
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
                    .foregroundStyle(.primary)
                Text(function.expression)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if function == store.current {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption.weight(.bold))
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.secondarySystemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
