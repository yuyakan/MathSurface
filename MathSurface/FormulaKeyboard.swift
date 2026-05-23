//
//  FormulaKeyboard.swift
//  MathSurface
//
//  Liquid Glass 風のカスタム数式キーボード
//

import SwiftUI

struct FormulaKeyboard: View {
    @Binding var text: String
    var variables: [String] = ["x", "y"]
    let onSubmit: () -> Void

    private let cellSpacing: CGFloat = 8

    private var rows: [[KeyboardKey]] {
        let varKeys: [KeyboardKey] = variables.map { .variable($0) }
        // 変数+定数で 4スロット埋める。足りなければ . と 0 で詰める
        var fourthRow: [KeyboardKey] = [.text("0"), .text(".")]
        fourthRow.append(contentsOf: varKeys)
        fourthRow.append(.constant("π"))
        fourthRow.append(.constant("e"))
        // ちょうど6スロットに切り詰める
        if fourthRow.count > 6 {
            fourthRow = Array(fourthRow.prefix(6))
        }
        return [
            [.text("7"), .text("8"), .text("9"), .text("("), .text(")"), .backspace],
            [.text("4"), .text("5"), .text("6"), .text("+"), .text("−"), .clear],
            [.text("1"), .text("2"), .text("3"), .text("×"), .text("÷"), .text("^")],
            fourthRow,
            [.function("sin"), .function("cos"), .function("tan"), .function("log"), .function("ln"), .function("exp")],
            [.function("sqrt"), .text("²"), .text("³"), .function("abs"), .function("hypot"), .submit]
        ]
    }

    var body: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<rows[rowIndex].count, id: \.self) { colIndex in
                        keyView(for: rows[rowIndex][colIndex])
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func keyView(for key: KeyboardKey) -> some View {
        switch key {
        case .text(let s):
            keyButton(label: s, font: .title3.weight(.medium), tint: .primary, fillStyle: .neutral) {
                insert(s)
            }

        case .variable(let v):
            keyButton(label: v, font: .title3.weight(.semibold), tint: .blue, fillStyle: .accentLight) {
                insert(v)
            }

        case .constant(let c):
            keyButton(label: c, font: .title3.weight(.semibold), tint: .purple, fillStyle: .accentLight) {
                insert(c)
            }

        case .function(let name):
            keyButton(label: name, font: .callout.weight(.semibold), tint: .indigo, fillStyle: .accentLight) {
                insert("\(name)(")
            }

        case .backspace:
            keyButton(symbol: "delete.left", tint: .orange, fillStyle: .accentLight) {
                if !text.isEmpty { text.removeLast() }
            }

        case .clear:
            keyButton(label: "AC", font: .callout.weight(.bold), tint: .orange, fillStyle: .accentLight) {
                text = ""
            }

        case .submit:
            keyButton(symbol: "checkmark", tint: .white, fillStyle: .submit) {
                onSubmit()
            }
        }
    }

    private func keyButton(
        label: String? = nil,
        symbol: String? = nil,
        font: Font = .title3.weight(.medium),
        tint: Color,
        fillStyle: KeyFill,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.title3.weight(.semibold))
                } else if let label {
                    Text(label)
                        .font(font)
                }
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background {
                switch fillStyle {
                case .neutral:
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.regularMaterial)
                case .accentLight:
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.15))
                case .submit:
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(fillStyle == .submit ? 0.3 : 0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func insert(_ s: String) {
        text.append(s)
    }
}

private enum KeyboardKey {
    case text(String)
    case variable(String)
    case constant(String)
    case function(String)
    case backspace
    case clear
    case submit
}

private enum KeyFill {
    case neutral
    case accentLight
    case submit
}
