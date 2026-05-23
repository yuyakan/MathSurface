//
//  FormulaParser.swift
//  MathSurface
//
//  Expression ライブラリのラッパー。文字列の数式を (x,y)->Double に変換。
//

import Foundation
// Foundation.Expression(Predicates) と名前衝突するので、必要な class だけ個別 import する
import class Expression.Expression

enum FormulaParseError: Error, LocalizedError {
    case empty
    case invalidSyntax(String)

    var errorDescription: String? {
        switch self {
        case .empty: "数式を入力してください"
        case .invalidSyntax(let msg): msg
        }
    }
}

enum FormulaParser {
    /// 入力された数式文字列をパースして、(x, y) -> Double のクロージャを返す
    static func parse(_ input: String) throws -> (Double, Double) -> Double {
        let normalized = normalize(input)
        guard !normalized.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw FormulaParseError.empty
        }

        let symbols: [Expression.Symbol: Expression.SymbolEvaluator] = [
            .function("sqrt", arity: 1): { args in sqrt(args[0]) },
            .function("abs", arity: 1): { args in abs(args[0]) },
            .function("sin", arity: 1): { args in sin(args[0]) },
            .function("cos", arity: 1): { args in cos(args[0]) },
            .function("tan", arity: 1): { args in tan(args[0]) },
            .function("asin", arity: 1): { args in asin(args[0]) },
            .function("acos", arity: 1): { args in acos(args[0]) },
            .function("atan", arity: 1): { args in atan(args[0]) },
            .function("atan2", arity: 2): { args in atan2(args[0], args[1]) },
            .function("exp", arity: 1): { args in exp(args[0]) },
            .function("log", arity: 1): { args in log(args[0]) },
            .function("ln", arity: 1): { args in log(args[0]) },
            .function("log10", arity: 1): { args in log10(args[0]) },
            .function("hypot", arity: 2): { args in hypot(args[0], args[1]) },
            .function("pow", arity: 2): { args in pow(args[0], args[1]) },
            .function("min", arity: 2): { args in min(args[0], args[1]) },
            .function("max", arity: 2): { args in max(args[0], args[1]) },
            .infix("^"): { args in pow(args[0], args[1]) }
        ]

        // 構文チェック: x, y に仮値を入れて一度評価
        do {
            let probe = Expression(
                normalized,
                constants: [
                    "x": 1, "y": 1, "π": .pi, "pi": .pi, "e": M_E
                ],
                symbols: symbols
            )
            _ = try probe.evaluate()
        } catch {
            throw FormulaParseError.invalidSyntax(error.localizedDescription)
        }

        return { x, y in
            let evaluator = Expression(
                normalized,
                constants: [
                    "x": x, "y": y, "π": .pi, "pi": .pi, "e": M_E
                ],
                symbols: symbols
            )
            return (try? evaluator.evaluate()) ?? .nan
        }
    }

    /// 入力中に使われる装飾的な記号を ASCII / Expression が解釈できる形に正規化
    private static func normalize(_ input: String) -> String {
        var s = input
        let mapping: [(String, String)] = [
            ("×", "*"),
            ("÷", "/"),
            ("−", "-"),
            ("－", "-"),
            ("ー", "-"),
            ("√", "sqrt"),
            ("²", "^2"),
            ("³", "^3"),
            (" ", "")
        ]
        for (from, to) in mapping {
            s = s.replacingOccurrences(of: from, with: to)
        }
        s = insertImplicitMultiplication(s)
        return s
    }

    /// 省略乗算を補完する: "2x" → "2*x"、")(", "2(", ")x" など
    private static func insertImplicitMultiplication(_ input: String) -> String {
        let chars = Array(input)
        guard !chars.isEmpty else { return input }
        var result: [Character] = []
        result.reserveCapacity(chars.count)

        for i in 0..<chars.count {
            let cur = chars[i]
            result.append(cur)
            guard i + 1 < chars.count else { continue }
            let next = chars[i + 1]
            if needsImplicitMul(left: cur, right: next, leftIndex: i, in: chars) {
                result.append("*")
            }
        }
        return String(result)
    }

    private static func needsImplicitMul(left: Character, right: Character, leftIndex: Int, in chars: [Character]) -> Bool {
        // 左: 数字 or ')' or 識別子末尾(英字) / 右: 識別子先頭(英字) or '(' or 数字(限定)
        let leftIsDigit = left.isNumber || left == "."
        let leftIsClose = left == ")"
        let leftIsAlpha = left.isLetter
        let rightIsAlpha = right.isLetter
        let rightIsOpen = right == "("
        let rightIsDigit = right.isNumber

        // 数字直後の '(' → 補完 例: 2(x+1) → 2*(x+1)
        if leftIsDigit && rightIsOpen { return true }
        // 数字直後の英字 → 補完 例: 2x → 2*x, 2sin(x) → 2*sin(x)
        if leftIsDigit && rightIsAlpha { return true }
        // ')' 直後の '(' or 英字 or 数字 → 補完
        if leftIsClose && (rightIsOpen || rightIsAlpha || rightIsDigit) { return true }
        // 英字(=変数 x,y,π,e のような一文字識別子)の直後に '(' は関数呼び出しの可能性が高いので補完しない
        // ただし「x(」のような単一変数 + '(' のケースは補完したいが、関数名と区別がつかないため
        // 一文字変数の場合のみ補完する：直前の英字塊が 1 文字 かつ x/y/e のいずれか
        if leftIsAlpha && rightIsOpen {
            // 左に向かって英字塊を見つける
            var start = leftIndex
            while start > 0, chars[start - 1].isLetter { start -= 1 }
            let token = String(chars[start...leftIndex])
            if token == "x" || token == "y" || token == "e" || token == "π" {
                return true
            }
        }
        return false
    }
}
