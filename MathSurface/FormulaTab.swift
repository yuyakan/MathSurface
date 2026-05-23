//
//  FormulaTab.swift
//  MathSurface
//

import SwiftUI

struct FormulaTab: View {
    @Environment(SurfaceStore.self) private var store

    @State private var text: String = "sin(x)*cos(y)"
    @State private var parsedFunction: SurfaceFunction?
    @State private var errorMessage: String?
    @State private var caretVisible: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    preview
                        .frame(height: 360)
                    formulaCard
                    FormulaKeyboard(text: $text) {
                        applyAndOfferSave()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .background(backgroundGradient)
            .navigationTitle("数式入力")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: text, initial: true) { _, _ in parse() }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    caretVisible = false
                }
            }
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

    @ViewBuilder
    private var preview: some View {
        if let parsedFunction {
            SurfaceView(function: parsedFunction, showsDescription: false)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                )
        } else {
            ContentUnavailableView(
                "数式を入力してください",
                systemImage: "function",
                description: Text("例: sin(x) * cos(y)、x^2 + y^2、exp(-(x^2+y^2))")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 0.5)
            )
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func parse() {
        do {
            let evaluator = try FormulaParser.parse(text)
            errorMessage = nil
            let span: Double = 10
            let range: ClosedRange<Double> = -span...span
            parsedFunction = SurfaceFunction(
                id: "custom-\(UUID().uuidString.prefix(8))",
                name: "カスタム関数",
                expression: "z = \(text)",
                category: .special,
                xRange: range,
                yRange: range,
                summary: "ユーザーが入力した数式"
            ) { x, y in evaluator(x, y) }
        } catch {
            errorMessage = error.localizedDescription
            parsedFunction = nil
        }
    }

    private func applyAndOfferSave() {
        guard let parsedFunction else { return }
        store.select(parsedFunction)
    }
}
