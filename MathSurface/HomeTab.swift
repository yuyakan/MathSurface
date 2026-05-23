//
//  HomeTab.swift
//  MathSurface
//

import SwiftUI
import SwiftData
import Charts

struct HomeTab: View {
    @Environment(SurfaceStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query private var saved: [SavedFormula]
    @State private var showRangePopover: Bool = false
    @State private var showsCrossSection: Bool = false
    @State private var showGallerySheet: Bool = false
    @State private var showEditorSheet: Bool = false
    @State private var showSectionKeyboard: Bool = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            VStack(spacing: 0) {
                SurfaceView(function: store.current, displayRadius: store.displayRadius, onEdit: {
                    showEditorSheet = true
                })
                if showsCrossSection {
                    crossSectionStrip
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showsCrossSection)
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
                        showsCrossSection.toggle()
                    } label: {
                        Image(systemName: "scissors")
                            .foregroundStyle(showsCrossSection ? .indigo : .secondary)
                    }
                    .accessibilityLabel("断面を表示")
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
                SurfaceGallerySheet { function in
                    store.select(function)
                    showGallerySheet = false
                }
            }
            .sheet(isPresented: $showEditorSheet) {
                SurfaceEditorSheet(initialText: expressionBody(store.current.expression)) { function in
                    store.select(function)
                }
            }
        }
    }

    // MARK: - Cross Section

    private var crossSectionStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionInputRow
            sectionChart
                .frame(height: 160)
            if showSectionKeyboard {
                sectionKeyboard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSectionKeyboard)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var sectionInputRow: some View {
        Button {
            showSectionKeyboard.toggle()
        } label: {
            HStack(spacing: 8) {
                Text("y =")
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(store.crossSectionYFormula.isEmpty ? " " : store.crossSectionYFormula)
                        .font(.system(.title3, design: .monospaced).weight(.medium))
                        .foregroundStyle(sectionParsed != nil ? Color.primary : Color.red)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: showSectionKeyboard ? "keyboard.chevron.compact.down" : "square.and.pencil")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.indigo)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(sectionInputBackground)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var sectionInputBackground: some View {
        if showSectionKeyboard {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.indigo.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.indigo.opacity(0.5), lineWidth: 1.5)
                )
        } else {
            Color.clear
        }
    }

    private var sectionKeyboard: some View {
        @Bindable var store = store
        return LinearKeyboard(text: $store.crossSectionYFormula) {
            showSectionKeyboard = false
        }
    }

    private var sectionParsed: ((Double) -> Double)? {
        try? LineFormulaParser.parse(store.crossSectionYFormula)
    }

    private var sectionChart: some View {
        let tRange = -store.displayRadius...store.displayRadius
        let samples = sampledCrossSection(tRange: tRange, count: 300)

        return Chart {
            ForEach(samples, id: \.t) { s in
                if s.z.isFinite {
                    LineMark(
                        x: .value("x", s.t),
                        y: .value("z", s.z)
                    )
                    .foregroundStyle(.indigo)
                    .interpolationMethod(.catmullRom)
                }
            }
            RuleMark(y: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
            RuleMark(x: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
        }
    }

    private func sampledCrossSection(tRange: ClosedRange<Double>, count: Int) -> [(t: Double, z: Double)] {
        guard count > 1 else { return [] }
        guard let yFn = sectionParsed else { return [] }
        let step = (tRange.upperBound - tRange.lowerBound) / Double(count - 1)
        let surface = store.current
        return (0..<count).map { i in
            let x = tRange.lowerBound + Double(i) * step
            let y = yFn(x)
            let z = surface.z(x: x, y: y)
            return (x, z)
        }
    }

    // MARK: - Range Popover

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

    // MARK: - Favorite

    private var isSaved: Bool {
        savedMatch != nil
    }

    private var savedMatch: SavedFormula? {
        let key = normalizedExpression(store.current.expression)
        return saved.first {
            ($0.kind ?? "surface") == "surface"
                && normalizedExpression("z = \($0.expression)") == key
        }
    }

    private func toggleFavorite() {
        if let match = savedMatch {
            modelContext.delete(match)
        } else {
            let exprBody = expressionBody(store.current.expression)
            let item = SavedFormula(name: store.current.name, expression: exprBody, kind: "surface")
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
