//
//  LineEditorSheet.swift
//  MathSurface
//
//  2D 関数を全画面で編集するシート（titleCard タップで起動）
//

import SwiftUI

struct LineEditorSheet: View {
    let initialText: String
    let initialKind: LineFunctionKind
    var title: String = "2D の式"
    let onCommit: (LineFunction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var kind: LineFunctionKind
    @State private var errorMessage: String?
    @State private var caretVisible: Bool = true

    init(initialText: String, initialKind: LineFunctionKind = .explicit, title: String = "2D の式", onCommit: @escaping (LineFunction) -> Void) {
        self.initialText = initialText
        self.initialKind = initialKind
        self.title = title
        self.onCommit = onCommit
        self._text = State(initialValue: initialText)
        self._kind = State(initialValue: initialKind)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    preview
                        .frame(height: 320)
                    modePicker
                    formulaCard
                    FormulaKeyboard(text: $text, variables: kind == .explicit ? ["x"] : ["x", "y"]) {
                        applyIfValid()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .onChange(of: text, initial: true) { _, _ in validate() }
            .onChange(of: kind) { _, _ in validate() }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    caretVisible = false
                }
            }
        }
    }

    private var modePicker: some View {
        Picker("形式", selection: $kind) {
            Text("y = ...").tag(LineFunctionKind.explicit)
            Text("0 = ...").tag(LineFunctionKind.implicit)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var preview: some View {
        if let function = parsedFunction {
            LineChartView(function: function, showsDescription: false)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                )
        } else {
            ContentUnavailableView(
                "数式を入力してください",
                systemImage: "function",
                description: Text(kind == .explicit ? "例: sin(x)、x^2、exp(-x^2)" : "例: x^2 + y^2 - 4、x*y - 1")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var formulaCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text(kind == .explicit ? "y =" : "0 =")
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(text.isEmpty ? " " : text)
                        .font(.system(.title3, design: .monospaced).weight(.medium))
                        .lineLimit(1)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.accentColor)
                        .frame(width: 2, height: 22)
                        .opacity(caretVisible ? 1 : 0)
                }
            }
            if let errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(errorMessage).lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var parsedFunction: LineFunction? {
        guard errorMessage == nil else { return nil }
        let span: Double = 10
        let range: ClosedRange<Double> = -span...span
        switch kind {
        case .explicit:
            guard let evaluator = try? LineFormulaParser.parse(text) else { return nil }
            return LineFunction(
                id: "custom-line-\(UUID().uuidString.prefix(8))",
                name: "カスタム関数",
                expression: "y = \(text)",
                category: .special,
                xRange: range,
                summary: ""
            ) { x in evaluator(x) }
        case .implicit:
            guard let evaluator = try? FormulaParser.parse(text) else { return nil }
            return LineFunction(
                id: "custom-line-imp-\(UUID().uuidString.prefix(8))",
                name: "カスタム関数",
                expression: "0 = \(text)",
                category: .special,
                xRange: range,
                summary: "",
                implicitEvaluator: { x, y in evaluator(x, y) }
            )
        }
    }

    private func validate() {
        do {
            switch kind {
            case .explicit: _ = try LineFormulaParser.parse(text)
            case .implicit: _ = try FormulaParser.parse(text)
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyIfValid() {
        guard let function = parsedFunction else { return }
        onCommit(function)
        dismiss()
    }
}
