//
//  ComplexLocusView.swift
//  MathSurface
//
//  軌跡サブモード: |z - α| = r などの陰関数プロット
//

import SwiftUI

struct ComplexLocusView: View {
    @Environment(SurfaceStore.self) private var store
    @State private var showKeyboard: Bool = false
    @State private var showGallery: Bool = false
    @State private var errorMessage: String?
    @State private var wasEditedManually: Bool = false

    private var radius: Double { store.complexRadius }

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 12) {
            ComplexPlaneView(
                radius: radius,
                contours: [contour].compactMap { $0 }
            )

            formulaCard
            ComplexRadiusSlider()

            if showKeyboard && wasEditedManually {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("入力された式によっては実際の数学的な軌跡と異なる表示になる場合があります")
                        .lineLimit(2)
                }
                .font(.caption2)
                .foregroundStyle(.orange)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .transition(.opacity)
            }

            if showKeyboard {
                let textBinding = Binding<String>(
                    get: { store.complexLocusFormula },
                    set: { store.complexLocusFormula = $0; wasEditedManually = true }
                )
                FormulaKeyboard(text: textBinding, variables: ["z"], complexMode: true) {
                    showKeyboard = false
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showKeyboard)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .onChange(of: store.complexLocusFormula, initial: true) { _, _ in validate() }
        .sheet(isPresented: $showGallery) {
            ComplexLocusGallerySheet { formula in
                store.complexLocusFormula = formula
                wasEditedManually = false
            }
        }
    }

    private var formulaCard: some View {
        HStack(spacing: 8) {
            Button {
                showKeyboard.toggle()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(store.complexLocusFormula.isEmpty ? " " : store.complexLocusFormula)
                                .font(.system(.title3, design: .monospaced).weight(.medium))
                                .foregroundStyle(errorMessage == nil ? Color.primary : Color.red)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: showKeyboard ? "keyboard.chevron.compact.down" : "square.and.pencil")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.indigo)
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
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            Button {
                showGallery = true
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.title3)
                    .foregroundStyle(.indigo)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("プリセット")
        }
    }

    private var contour: ComplexPlaneContour? {
        guard let f = try? ComplexFormulaParser.parseEquation(store.complexLocusFormula) else { return nil }
        let segs = ContourBuilder.contourSegments(
            f: f,
            xRange: -radius...radius,
            yRange: -radius...radius,
            level: 0,
            resolution: 100
        )
        return ComplexPlaneContour(segments: segs, color: .indigo)
    }

    private func validate() {
        do {
            _ = try ComplexFormulaParser.parseEquation(store.complexLocusFormula)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
