//
//  LinearKeyboard.swift
//  MathSurface
//
//  y = ax + b のような線形式入力に特化した小型キーボード
//

import SwiftUI

struct LinearKeyboard: View {
    @Binding var text: String
    var variable: String = "x"
    let onSubmit: () -> Void

    private let cellSpacing: CGFloat = 8

    private var rows: [[Key]] {
        let fourthRow: [Key] = variable.isEmpty
            ? [.text("0"), .text("."), .empty, .submit]
            : [.text("0"), .text("."), .text(variable), .submit]
        return [
            [.text("7"), .text("8"), .text("9"), .backspace],
            [.text("4"), .text("5"), .text("6"), .text("+")],
            [.text("1"), .text("2"), .text("3"), .text("−")],
            fourthRow
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
            HStack(spacing: cellSpacing) {
                clearButton
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
    private func keyView(for key: Key) -> some View {
        switch key {
        case .text(let s):
            let isVar = (s == variable && !variable.isEmpty)
            keyButton(label: s, tint: isVar ? .blue : .primary, fill: isVar ? .accentLight(.blue) : .neutral) {
                text.append(s)
            }
        case .backspace:
            keyButton(symbol: "delete.left", tint: .orange, fill: .accentLight(.orange)) {
                if !text.isEmpty { text.removeLast() }
            }
        case .submit:
            keyButton(symbol: "checkmark", tint: .white, fill: .submit) {
                onSubmit()
            }
        case .empty:
            Color.clear.frame(maxWidth: .infinity, minHeight: 46)
        }
    }

    private var clearButton: some View {
        keyButton(label: "AC", tint: .orange, fill: .accentLight(.orange)) {
            text = ""
        }
    }

    private func keyButton(label: String? = nil, symbol: String? = nil, tint: Color, fill: Fill, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let symbol {
                    Image(systemName: symbol).font(.title3.weight(.semibold))
                } else if let label {
                    Text(label).font(.title3.weight(.medium))
                }
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(background(for: fill, tint: tint))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func background(for fill: Fill, tint: Color) -> some View {
        switch fill {
        case .neutral:
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.regularMaterial)
        case .accentLight(let color):
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color.opacity(0.15))
        case .submit:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private enum Key {
        case text(String)
        case backspace
        case submit
        case empty
    }

    private enum Fill {
        case neutral
        case accentLight(Color)
        case submit
    }
}
