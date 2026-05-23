//
//  LineEditorSheet.swift
//  MathSurface
//
//  2D 関数を全画面で編集するシート（titleCard タップで起動）
//

import SwiftUI

struct LineEditorSheet: View {
    let initialText: String
    let onCommit: (LineFunction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var errorMessage: String?

    init(initialText: String, onCommit: @escaping (LineFunction) -> Void) {
        self.initialText = initialText
        self.onCommit = onCommit
        self._text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    preview
                        .frame(height: 320)
                    formulaCard
                    FormulaKeyboard(text: $text, variables: ["x"]) {
                        applyIfValid()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .navigationTitle("2D の式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .onChange(of: text, initial: true) { _, _ in validate() }
        }
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
                description: Text("例: sin(x)、x^2、exp(-x^2)")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var formulaCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("y =")
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(text.isEmpty ? " " : text)
                        .font(.system(.title3, design: .monospaced).weight(.medium))
                        .lineLimit(1)
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
        guard let evaluator = try? LineFormulaParser.parse(text) else { return nil }
        let span: Double = 10
        let range: ClosedRange<Double> = -span...span
        return LineFunction(
            id: "custom-line-\(UUID().uuidString.prefix(8))",
            name: "カスタム関数",
            expression: "y = \(text)",
            category: .special,
            xRange: range,
            summary: ""
        ) { x in evaluator(x) }
    }

    private func validate() {
        do {
            _ = try LineFormulaParser.parse(text)
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
