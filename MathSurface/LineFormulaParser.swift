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
        case .empty: "数式を入力してください"
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
        if lower.contains("missing") && lower.contains("parenthes") { return "カッコが閉じていません" }
        if lower.contains("unexpected") { return "式の書き方が正しくありません" }
        if lower.contains("empty") { return "式が空です" }
        if lower.contains("undefined") || lower.contains("unknown") { return "使えない記号があります" }
        if lower.contains("argument") { return "関数の引数の数が違います" }
        if lower.contains("operand") { return "演算子の前後を確認してください" }
        return "式を確認してください"
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

    /// 省略乗算を補完する: "2x" → "2*x", "2(x+1)" → "2*(x+1)" など
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
