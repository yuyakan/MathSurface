//
//  HomeTab.swift
//  MathSurface
//

import SwiftUI
import SwiftData

struct HomeTab: View {
    @Environment(SurfaceStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query private var saved: [SavedFormula]
    @State private var showRangePopover: Bool = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            SurfaceView(function: store.current, displayRadius: store.displayRadius)
                .navigationTitle(store.current.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            toggleFavorite()
                        } label: {
                            Image(systemName: isSaved ? "star.fill" : "star")
                                .foregroundStyle(isSaved ? .yellow : .secondary)
                        }
                        .accessibilityLabel(isSaved ? "お気に入りから削除" : "お気に入りに保存")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showRangePopover.toggle()
                        } label: {
                            Image(systemName: "ruler")
                        }
                        .popover(isPresented: $showRangePopover, arrowEdge: .top) {
                            rangePopoverContent(store: $store)
                                .presentationCompactAdaptation(.popover)
                        }
                    }
                }
        }
    }

    private func rangePopoverContent(store: Bindable<SurfaceStore>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("表示範囲")
                    .font(.headline)
                Spacer()
                Text("±\(Int(store.wrappedValue.displayRadius))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: store.displayRadius, in: 3...30, step: 1) {
                Text("範囲")
            } minimumValueLabel: {
                Text("3").font(.caption2).foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("30").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    /// 現在の関数が保存済みかどうか
    private var isSaved: Bool {
        savedMatch != nil
    }

    private var savedMatch: SavedFormula? {
        let key = normalizedExpression(store.current.expression)
        return saved.first { normalizedExpression("z = \($0.expression)") == key }
    }

    private func toggleFavorite() {
        if let match = savedMatch {
            modelContext.delete(match)
        } else {
            let exprBody = expressionBody(store.current.expression)
            let item = SavedFormula(name: store.current.name, expression: exprBody)
            modelContext.insert(item)
        }
        try? modelContext.save()
    }

    /// "z = sin(x) * cos(y)" → "sin(x) * cos(y)" のような本体だけを取り出す
    private func expressionBody(_ expression: String) -> String {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        if let range = trimmed.range(of: "=") {
            return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return trimmed
    }

    /// 重複判定用に空白を除去
    private func normalizedExpression(_ s: String) -> String {
        s.replacingOccurrences(of: " ", with: "")
    }
}
