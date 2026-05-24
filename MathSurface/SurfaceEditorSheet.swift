//
//  SurfaceEditorSheet.swift
//  MathSurface
//
//  3D 関数を全画面で編集するシート（titleCard タップで起動）
//

import SwiftUI

struct SurfaceEditorSheet: View {
    let initialText: String
    var title: String = "3Dの式"
    let onCommit: (SurfaceFunction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var errorMessage: String?
    @State private var caretVisible: Bool = true

    init(initialText: String, title: String = "3Dの式", onCommit: @escaping (SurfaceFunction) -> Void) {
        self.initialText = initialText
        self.title = title
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
                    FormulaKeyboard(text: $text) {
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
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    caretVisible = false
                }
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let function = parsedFunction {
            SurfaceView(function: function, showsDescription: false)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                )
        } else {
            ContentUnavailableView(
                "数式を入力してください",
                systemImage: "function",
                description: Text("例: sin(x)*cos(y)、x^2+y^2、exp(-(x^2+y^2))")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var formulaCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("z =")
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

    private var parsedFunction: SurfaceFunction? {
        guard errorMessage == nil else { return nil }
        guard let evaluator = try? FormulaParser.parse(text) else { return nil }
        let span: Double = 10
        let range: ClosedRange<Double> = -span...span
        return SurfaceFunction(
            id: "custom-\(UUID().uuidString.prefix(8))",
            name: "カスタム関数",
            expression: "z = \(text)",
            category: .special,
            xRange: range,
            yRange: range,
            summary: ""
        ) { x, y in evaluator(x, y) }
    }

    private func validate() {
        do {
            _ = try FormulaParser.parse(text)
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
