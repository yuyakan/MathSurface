//
//  FavoritesTab.swift
//  MathSurface
//

import SwiftUI
import SwiftData

struct FavoritesTab: View {
    @Environment(SurfaceStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \SavedFormula.createdAt, order: .reverse)
    private var saved: [SavedFormula]

    var body: some View {
        NavigationStack {
            Group {
                if saved.isEmpty {
                    ContentUnavailableView(
                        "お気に入りはまだありません",
                        systemImage: "star",
                        description: Text("数式タブから ✓ ボタンで保存できます")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(saved) { item in
                                row(for: item)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(backgroundGradient)
            .navigationTitle("お気に入り")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel("設定")
                }
            }
        }
    }

    private func row(for item: SavedFormula) -> some View {
        let isLine = item.isLine
        let prefix = isLine ? "y" : "z"
        let icon = isLine ? "chart.xyaxis.line" : "cube"
        let gradient = isLine
            ? LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)

        return Button {
            if isLine {
                if let function = item.makeLineFunction() {
                    store.selectLine(function)
                }
            } else {
                if let function = item.makeFunction() {
                    store.select(function)
                }
            }
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(gradient)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: icon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                ScrollView(.horizontal, showsIndicators: false) {
                    Text("\(prefix) = \(item.expression)")
                        .font(.system(.title3, design: .monospaced).weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
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
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private var backgroundGradient: some View {
        AppTheme.backgroundGradient.ignoresSafeArea()
    }
}
