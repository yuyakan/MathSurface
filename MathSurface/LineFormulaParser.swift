//
//  LineFormulaParser.swift
//  MathSurface
//
//  1変数 y = f(x) 専用の数式パーサ
//

import Foundation
import class Expression.Expression

enum LineFormulaParseError: Error, LocalizedError {
    case empty
    case invalidSyntax(String)

    var errorDescription: String? {
        switch self {
        case .empty: String(localized: "数式を入力してください")
        case .invalidSyntax(let msg): msg
        }
    }
}

enum LineFormulaParser {
    /// 入力された数式文字列をパースして、(x) -> Double のクロージャを返す
    static func parse(_ input: String) throws -> (Double) -> Double {
        let normalized = normalize(input)
        guard !normalized.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw LineFormulaParseError.empty
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
            .function("exp", arity: 1): { args in exp(args[0]) },
            .function("log", arity: 1): { args in log(args[0]) },
            .function("ln", arity: 1): { args in log(args[0]) },
            .function("log10", arity: 1): { args in log10(args[0]) },
            .function("pow", arity: 2): { args in pow(args[0], args[1]) },
            .function("min", arity: 2): { args in min(args[0], args[1]) },
            .function("max", arity: 2): { args in max(args[0], args[1]) },
            .infix("^"): { args in pow(args[0], args[1]) }
        ]

        // 構文チェック: x に仮値を入れて一度評価
        do {
            let probe = Expression(
                normalized,
                constants: ["x": 1, "π": .pi, "pi": .pi, "e": M_E],
                symbols: symbols
            )
            _ = try probe.evaluate()
        } catch {
            throw LineFormulaParseError.invalidSyntax(humanReadable(error.localizedDescription))
        }

        return { x in
            let evaluator = Expression(
                normalized,
                constants: ["x": x, "π": .pi, "pi": .pi, "e": M_E],
                symbols: symbols
            )
            return (try? evaluator.evaluate()) ?? .nan
        }
    }

    private static func humanReadable(_ message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("missing") && lower.contains("parenthes") { return String(localized: "カッコが閉じていません") }
        if lower.contains("unexpected") { return String(localized: "式の書き方が正しくありません") }
        if lower.contains("empty") { return String(localized: "式が空です") }
        if lower.contains("undefined") || lower.contains("unknown") { return String(localized: "使えない記号があります") }
        if lower.contains("argument") { return String(localized: "関数の引数の数が違います") }
        if lower.contains("operand") { return String(localized: "演算子の前後を確認してください") }
        return String(localized: "式を確認してください")
    }

    private static func normalize(_ input: String) -> String {
        var s = input
        let mapping: [(String, String)] = [
            ("×", "*"),
            ("·", "*"),
            ("・", "*"),
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

    /// 省略乗算を補完する: "2x" → "2*x", "2(x+1)" → "2*(x+1)", "xx" → "x*x" など
    private static func insertImplicitMultiplication(_ input: String) -> String {
        let chars = splitVariableRuns(Array(input))
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

    /// 英字塊が単一文字変数 (x, π) のみで構成される場合に各文字間に '*' を挟む。
    /// 関数名 (sin, cos, ...) や定数 (pi, e, ln) は変数ではないので分割しない。
    private static func splitVariableRuns(_ chars: [Character]) -> [Character] {
        guard !chars.isEmpty else { return chars }
        let singleVars: Set<Character> = ["x", "π"]
        var result: [Character] = []
        result.reserveCapacity(chars.count)
        var i = 0
        while i < chars.count {
            if chars[i].isLetter {
                var j = i
                while j < chars.count, chars[j].isLetter { j += 1 }
                let run = chars[i..<j]
                if run.allSatisfy({ singleVars.contains($0) }) {
                    for (k, c) in run.enumerated() {
                        if k > 0 { result.append("*") }
                        result.append(c)
                    }
                } else {
                    result.append(contentsOf: run)
                }
                i = j
            } else {
                result.append(chars[i])
                i += 1
            }
        }
        return result
    }

    private static func needsImplicitMul(left: Character, right: Character, leftIndex: Int, in chars: [Character]) -> Bool {
        let leftIsDigit = left.isNumber || left == "."
        let leftIsClose = left == ")"
        let leftIsAlpha = left.isLetter
        let rightIsAlpha = right.isLetter
        let rightIsOpen = right == "("
        let rightIsDigit = right.isNumber

        if leftIsDigit && rightIsOpen { return true }
        if leftIsDigit && rightIsAlpha { return true }
        if leftIsClose && (rightIsOpen || rightIsAlpha || rightIsDigit) { return true }
        if leftIsAlpha && rightIsOpen {
            var start = leftIndex
            while start > 0, chars[start - 1].isLetter { start -= 1 }
            let token = String(chars[start...leftIndex])
            if token == "x" || token == "e" || token == "π" {
                return true
            }
        }
        return false
    }
}
