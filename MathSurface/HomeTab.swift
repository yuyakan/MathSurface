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
    @State private var showCompareEditor: Bool = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 0) {
                SurfaceView(
                    function: store.current,
                    compareFunction: store.compareFunction,
                    displayRadius: store.displayRadius,
                    onEdit: { showEditorSheet = true },
                    onCompareEdit: { showCompareEditor = true }
                )
                if showsCrossSection {
                    crossSectionStrip
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
                        if store.compareFunction == nil {
                            // 比較追加: エディタを起動（決定したら compareFunction に入る）
                            showCompareEditor = true
                        } else {
                            // 既に比較中: 解除
                            store.compareFunction = nil
                        }
                    } label: {
                        Image(systemName: store.compareFunction == nil ? "plus.rectangle.on.rectangle" : "rectangle.on.rectangle.fill")
                            .foregroundStyle(store.compareFunction == nil ? Color.secondary : Color.pink)
                    }
                    .accessibilityLabel(store.compareFunction == nil ? "比較を追加" : "比較を解除")
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
                    InterstitialAdManager.shared.notifyTrigger()
                }
            }
            .sheet(isPresented: $showEditorSheet) {
                SurfaceEditorSheet(initialText: expressionBody(store.current.expression)) { function in
                    store.select(function)
                    InterstitialAdManager.shared.notifyTrigger()
                }
            }
            .sheet(isPresented: $showCompareEditor) {
                let initial = store.compareFunction.map { expressionBody($0.expression) }
                    ?? expressionBody(store.current.expression)
                SurfaceEditorSheet(initialText: initial, title: String(localized: "比較の式")) { function in
                    store.compareFunction = function
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
        @Bindable var store = store
        return HStack(spacing: 8) {
            Picker("軸", selection: $store.crossSectionLHS) {
                Text("y =").tag(SurfaceStore.CrossSectionLHS.yEqualsXFormula)
                Text("x =").tag(SurfaceStore.CrossSectionLHS.xEqualsYFormula)
                Text("z =").tag(SurfaceStore.CrossSectionLHS.zConstant)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            Button {
                showSectionKeyboard.toggle()
            } label: {
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(store.crossSectionFormula.isEmpty ? " " : store.crossSectionFormula)
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
        let variable: String
        switch store.crossSectionLHS {
        case .yEqualsXFormula: variable = "x"
        case .xEqualsYFormula: variable = "y"
        case .zConstant:       variable = ""  // 定数のみ、変数キーは隠す
        }
        return LinearKeyboard(text: $store.crossSectionFormula, variable: variable) {
            showSectionKeyboard = false
        }
    }

    private var sectionParsed: ((Double) -> Double)? {
        switch store.crossSectionLHS {
        case .yEqualsXFormula:
            return try? LineFormulaParser.parse(store.crossSectionFormula)
        case .xEqualsYFormula:
            return try? LineFormulaParser.parse(renameVariable(store.crossSectionFormula, from: "y", to: "x"))
        case .zConstant:
            // z= モードでは定数値（評価は1回だけ）
            guard let evaluator = try? LineFormulaParser.parse(store.crossSectionFormula) else { return nil }
            // x に何を入れても同じ定数を返す前提
            let value = evaluator(0)
            return { _ in value }
        }
    }

    @ViewBuilder
    private var sectionChart: some View {
        switch store.crossSectionLHS {
        case .yEqualsXFormula, .xEqualsYFormula:
            sectionChartLine
        case .zConstant:
            sectionChartContour
        }
    }

    private var sectionAxisLabel: String {
        store.crossSectionLHS == .yEqualsXFormula ? "x" : "y"
    }

    private var sectionChartLine: some View {
        let tRange = -store.displayRadius...store.displayRadius
        let samples = sampledCrossSection(tRange: tRange, count: 300)
        let axisLabel = sectionAxisLabel

        return Chart {
            ForEach(samples, id: \.t) { s in
                if s.z.isFinite {
                    LineMark(
                        x: .value(axisLabel, s.t),
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

    private var sectionChartContour: some View {
        let level = sectionParsed?(0) ?? 0
        let r = store.displayRadius
        let segments = ContourBuilder.contourSegments(
            f: { x, y in store.current.z(x: x, y: y) },
            xRange: -r...r,
            yRange: -r...r,
            level: level,
            resolution: 80
        )

        return Chart {
            ForEach(0..<segments.count, id: \.self) { i in
                let seg = segments[i]
                LineMark(
                    x: .value("x", seg.start.x),
                    y: .value("y", seg.start.y),
                    series: .value("seg", i)
                )
                .foregroundStyle(.indigo)
                LineMark(
                    x: .value("x", seg.end.x),
                    y: .value("y", seg.end.y),
                    series: .value("seg", i)
                )
                .foregroundStyle(.indigo)
            }
            RuleMark(y: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
            RuleMark(x: .value("axis", 0))
                .foregroundStyle(.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
        }
        .chartXScale(domain: -r...r)
        .chartYScale(domain: -r...r)
    }

    private func sampledCrossSection(tRange: ClosedRange<Double>, count: Int) -> [(t: Double, z: Double)] {
        guard count > 1 else { return [] }
        guard let fn = sectionParsed else { return [] }
        let step = (tRange.upperBound - tRange.lowerBound) / Double(count - 1)
        let surface = store.current
        return (0..<count).map { i in
            let t = tRange.lowerBound + Double(i) * step
            let z: Double
            switch store.crossSectionLHS {
            case .yEqualsXFormula: z = surface.z(x: t, y: fn(t))
            case .xEqualsYFormula: z = surface.z(x: fn(t), y: t)
            case .zConstant:       z = .nan  // 通らない
            }
            return (t, z)
        }
    }

    /// 識別子境界を考慮して変数名を置換（"y" を "x" に等）
    private func renameVariable(_ input: String, from src: Character, to dst: Character) -> String {
        let chars = Array(input)
        var result: [Character] = []
        result.reserveCapacity(chars.count)
        for i in 0..<chars.count {
            let c = chars[i]
            if c == src {
                let prev = i > 0 ? chars[i - 1] : nil
                let next = i + 1 < chars.count ? chars[i + 1] : nil
                let prevIsAlpha = prev.map { $0.isLetter } ?? false
                let nextIsAlphaOrDigit = next.map { $0.isLetter || $0.isNumber } ?? false
                if !prevIsAlpha && !nextIsAlphaOrDigit {
                    result.append(dst)
                    continue
                }
            }
            result.append(c)
        }
        return String(result)
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
            try? modelContext.save()
        } else {
            let exprBody = expressionBody(store.current.expression)
            let item = SavedFormula(name: store.current.name, expression: exprBody, kind: "surface")
            modelContext.insert(item)
            try? modelContext.save()
            InterstitialAdManager.shared.notifyTrigger()
        }
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
