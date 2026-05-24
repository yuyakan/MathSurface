//
//  LineTab.swift
//  MathSurface
//

import SwiftUI
import SwiftData

struct LineTab: View {
    @Environment(SurfaceStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query private var saved: [SavedFormula]
    @State private var showRangePopover: Bool = false
    @State private var showGallerySheet: Bool = false
    @State private var showEditorSheet: Bool = false
    @State private var showCompareEditor: Bool = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            LineChartView(
                function: store.currentLine,
                compareFunction: store.compareLine,
                displayRadius: store.displayRadius,
                onEdit: { showEditorSheet = true },
                onCompareEdit: { showCompareEditor = true }
            )
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            toggleFavorite()
                        } label: {
                            Image(systemName: isSaved ? "star.fill" : "star")
                                .foregroundStyle(isSaved ? .yellow : .secondary)
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showGallerySheet = true
                        } label: {
                            Image(systemName: "square.grid.2x2")
                        }
                        .accessibilityLabel("ギャラリー")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if store.compareLine == nil {
                                showCompareEditor = true
                            } else {
                                store.compareLine = nil
                            }
                        } label: {
                            Image(systemName: store.compareLine == nil ? "plus.rectangle.on.rectangle" : "rectangle.on.rectangle.fill")
                                .foregroundStyle(store.compareLine == nil ? Color.secondary : Color.pink)
                        }
                        .accessibilityLabel(store.compareLine == nil ? "比較を追加" : "比較を解除")
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
                .sheet(isPresented: $showGallerySheet) {
                    LineGallerySheet { function in
                        store.selectLine(function)
                        showGallerySheet = false
                    }
                }
                .sheet(isPresented: $showEditorSheet) {
                    LineEditorSheet(initialText: expressionBody(store.currentLine.expression), initialKind: store.currentLine.kind) { function in
                        store.selectLine(function)
                    }
                }
                .sheet(isPresented: $showCompareEditor) {
                    let initialText = store.compareLine.map { expressionBody($0.expression) }
                        ?? expressionBody(store.currentLine.expression)
                    let initialKind = store.compareLine?.kind ?? store.currentLine.kind
                    LineEditorSheet(initialText: initialText, initialKind: initialKind, title: "比較の式") { function in
                        store.compareLine = function
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

    private var isSaved: Bool {
        savedMatch != nil
    }

    private var savedMatch: SavedFormula? {
        let key = normalizedExpression(store.currentLine.expression)
        return saved.first {
            ($0.kind ?? "surface") == "line"
                && normalizedExpression("y = \($0.expression)") == key
        }
    }

    private func toggleFavorite() {
        if let match = savedMatch {
            modelContext.delete(match)
        } else {
            let exprBody = expressionBody(store.currentLine.expression)
            let item = SavedFormula(name: store.currentLine.name, expression: exprBody, kind: "line")
            modelContext.insert(item)
        }
        try? modelContext.save()
    }

    private func expressionBody(_ expression: String) -> String {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        if let range = trimmed.range(of: "=") {
            return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return trimmed
    }


    private func normalizedExpression(_ s: String) -> String {
        s.replacingOccurrences(of: " ", with: "")
    }
}

// MARK: - Gallery Sheet

struct LineGallerySheet: View {
    let onPick: (LineFunction) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(LinePresetLibrary.byCategory(), id: \.0) { category, functions in
                        if !functions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: category.symbolName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(category.tint)
                                    Text(category.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                                ForEach(functions) { function in
                                    Button {
                                        onPick(function)
                                    } label: {
                                        LineRow(function: function)
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
            .navigationTitle("1変数関数")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

private struct LineRow: View {
    let function: LineFunction
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

