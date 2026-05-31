//
//  ComplexFormulaParser.swift
//  MathSurface
//
//  複素数を扱う独自の再帰下降パーサ。
//  z, i を識別子として扱い、|...|, arg(...), conj(...), Re(...), Im(...) や
//  四則演算、^(整数または実数)、関数 sin/cos/exp 等もサポート。
//  等式 LHS = RHS は F(x,y) = (LHS - RHS).magnitudeSquared または
//  Re/Im 別計算でゼロ等高線を取る形に変換する。
//

import Foundation

enum ComplexFormulaParseError: Error, LocalizedError {
    case empty
    case invalidSyntax(String)
    case missingEquals

    var errorDescription: String? {
        switch self {
        case .empty: String(localized: "数式を入力してください")
        case .invalidSyntax(let msg): msg
        case .missingEquals: String(localized: "「=」を含む式を入力してください")
        }
    }
}

enum ComplexFormulaParser {
    /// 入力式（LHS = RHS）を、ContourBuilder が扱える (x, y) -> Double の零点関数に変換。
    /// LHS が複素数で評価される場合は |LHS - RHS|² - 0 を、実数で評価される場合は LHS - RHS を返す。
    static func parseEquation(_ input: String) throws -> (Double, Double) -> Double {
        let normalized = normalize(input)
        guard !normalized.isEmpty else { throw ComplexFormulaParseError.empty }
        let parts = normalized.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 2 else { throw ComplexFormulaParseError.missingEquals }
        let lhs = parts[0].trimmingCharacters(in: .whitespaces)
        let rhs = parts[1].trimmingCharacters(in: .whitespaces)

        // 構文チェック: 仮値で評価
        do {
            _ = try evaluateAsValue(lhs, x: 0.1, y: 0.2)
            _ = try evaluateAsValue(rhs, x: 0.1, y: 0.2)
        } catch let e as ComplexFormulaParseError {
            throw e
        } catch {
            throw ComplexFormulaParseError.invalidSyntax(error.localizedDescription)
        }

        return { x, y in
            do {
                let l = try evaluateAsValue(lhs, x: x, y: y)
                let r = try evaluateAsValue(rhs, x: x, y: y)
                // 差分を複素数として計算
                let d: Complex = l.asComplex - r.asComplex
                // 虚部が（数値誤差を除き）0 なら実部の符号で評価（符号変化を保ち marching squares で線が引ける）
                if abs(d.im) < 1e-9 {
                    return d.re
                }
                // 純粋な複素式: |d|² を返す（=0 は孤立点になることが多い）
                return d.re * d.re + d.im * d.im
            } catch {
                return .nan
            }
        }
    }

    // MARK: - Normalize

    private static func normalize(_ input: String) -> String {
        var s = input
        let mapping: [(String, String)] = [
            ("×", "*"), ("·", "*"), ("・", "*"), ("÷", "/"),
            ("−", "-"), ("－", "-"), ("ー", "-"),
            ("²", "^2"), ("³", "^3"),
            ("π", "pi"),
            (" ", "")
        ]
        for (from, to) in mapping {
            s = s.replacingOccurrences(of: from, with: to)
        }
        return s
    }

    // MARK: - Value type

    enum Value {
        case real(Double)
        case complex(Complex)

        var asComplex: Complex {
            switch self {
            case .real(let r): return Complex(re: r, im: 0)
            case .complex(let c): return c
            }
        }
        var asReal: Double? {
            switch self {
            case .real(let r): return r
            case .complex(let c): return c.im == 0 ? c.re : nil
            }
        }
    }

    // MARK: - Tokenizer

    private enum Token: Equatable {
        case number(Double)
        case ident(String)
        case op(Character)  // + - * / ^
        case lparen, rparen
        case bar  // |
        case comma
    }

    private static func tokenize(_ input: String) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(input)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace { i += 1; continue }
            if c.isNumber || c == "." {
                var j = i
                while j < chars.count, chars[j].isNumber || chars[j] == "." { j += 1 }
                let str = String(chars[i..<j])
                guard let val = Double(str) else {
                    throw ComplexFormulaParseError.invalidSyntax(String(localized: "数値の解釈に失敗: \(str)"))
                }
                tokens.append(.number(val))
                i = j
            } else if c.isLetter {
                var j = i
                while j < chars.count, chars[j].isLetter || chars[j].isNumber { j += 1 }
                tokens.append(.ident(String(chars[i..<j])))
                i = j
            } else if "+-*/^".contains(c) {
                tokens.append(.op(c)); i += 1
            } else if c == "(" {
                tokens.append(.lparen); i += 1
            } else if c == ")" {
                tokens.append(.rparen); i += 1
            } else if c == "|" {
                tokens.append(.bar); i += 1
            } else if c == "," {
                tokens.append(.comma); i += 1
            } else {
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "使えない記号: \(c)"))
            }
        }
        return tokens
    }

    // MARK: - Parser (recursive descent)

    private final class Parser {
        let tokens: [Token]
        var pos = 0
        let x: Double
        let y: Double
        /// |...| の入れ子深さ。>0 のとき内側の式は閉じ bar を見たら止まる
        var barDepth = 0

        init(tokens: [Token], x: Double, y: Double) {
            self.tokens = tokens
            self.x = x
            self.y = y
        }

        var peek: Token? { pos < tokens.count ? tokens[pos] : nil }
        func eat() -> Token? { let t = peek; if t != nil { pos += 1 }; return t }

        func parseExpression() throws -> Value {
            var left = try parseTerm()
            while case .op(let c)? = peek, c == "+" || c == "-" {
                _ = eat()
                let right = try parseTerm()
                left = applyBinary(left, c, right)
            }
            return left
        }

        func parseTerm() throws -> Value {
            var left = try parseFactor()
            while case .op(let c)? = peek, c == "*" || c == "/" {
                _ = eat()
                let right = try parseFactor()
                left = applyBinary(left, c, right)
            }
            // 暗黙乗算: 数字や閉じカッコの直後に識別子・カッコ・|...| が来た場合
            // ただし bar に関しては、barDepth が 0（つまり |...| の中にいない）ときだけ起点として許可
            while let next = peek {
                let isImplicit: Bool
                switch next {
                case .ident, .lparen: isImplicit = true
                case .bar: isImplicit = (barDepth == 0)
                default: isImplicit = false
                }
                if isImplicit {
                    let right = try parseFactor()
                    left = applyBinary(left, "*", right)
                } else {
                    break
                }
            }
            return left
        }

        func parseFactor() throws -> Value {
            var base = try parseUnary()
            if case .op("^")? = peek {
                _ = eat()
                let exp = try parseUnary()
                base = applyPower(base, exp)
            }
            return base
        }

        func parseUnary() throws -> Value {
            if case .op("-")? = peek {
                _ = eat()
                let v = try parseUnary()
                switch v {
                case .real(let r): return .real(-r)
                case .complex(let c): return .complex(-c)
                }
            }
            if case .op("+")? = peek {
                _ = eat()
                return try parseUnary()
            }
            return try parsePrimary()
        }

        func parsePrimary() throws -> Value {
            guard let t = eat() else {
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "式が予期せず終了しました"))
            }
            switch t {
            case .number(let v):
                return .real(v)
            case .lparen:
                let v = try parseExpression()
                guard case .rparen? = eat() else {
                    throw ComplexFormulaParseError.invalidSyntax(String(localized: "カッコが閉じていません"))
                }
                return v
            case .bar:
                barDepth += 1
                let inner = try parseExpression()
                barDepth -= 1
                guard case .bar? = eat() else {
                    throw ComplexFormulaParseError.invalidSyntax(String(localized: "|...| が閉じていません"))
                }
                return .real(inner.asComplex.magnitude)
            case .ident(let name):
                return try parseIdentifier(name)
            case .op(let c):
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "予期しない演算子: \(c)"))
            case .rparen, .comma:
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "構文エラー"))
            }
        }

        func parseIdentifier(_ name: String) throws -> Value {
            // 関数呼び出しチェック
            if case .lparen? = peek {
                _ = eat()  // (
                var args: [Value] = [try parseExpression()]
                while case .comma? = peek {
                    _ = eat()
                    args.append(try parseExpression())
                }
                guard case .rparen? = eat() else {
                    throw ComplexFormulaParseError.invalidSyntax(String(localized: "関数の ) が見つかりません"))
                }
                return try callFunction(name, args: args)
            }
            // 定数・変数
            switch name {
            case "i": return .complex(.i)
            case "z": return .complex(Complex(re: x, im: y))
            case "x": return .real(x)
            case "y": return .real(y)
            case "pi": return .real(.pi)
            case "e": return .real(M_E)
            default:
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "使えない記号: \(name)"))
            }
        }

        func callFunction(_ name: String, args: [Value]) throws -> Value {
            switch (name, args.count) {
            case ("abs", 1): return .real(args[0].asComplex.magnitude)
            case ("arg", 1):
                let c = args[0].asComplex
                // 原点近傍は atan2 が不安定なので NaN
                if c.magnitude < 0.05 {
                    return .real(.nan)
                }
                // atan2 の不連続線（負実軸 y≈0, x<0）近傍では NaN を返し、
                // marching squares で偽の符号変化線が引かれるのを防ぐ
                if c.re < 0 && abs(c.im) < 0.03 {
                    return .real(.nan)
                }
                return .real(c.argument)
            case ("conj", 1): return .complex(args[0].asComplex.conjugate)
            case ("Re", 1): return .real(args[0].asComplex.re)
            case ("Im", 1): return .real(args[0].asComplex.im)
            case ("sqrt", 1):
                if let r = args[0].asReal { return .real(sqrt(r)) }
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "sqrt は実数引数のみ"))
            case ("sin", 1):
                if let r = args[0].asReal { return .real(sin(r)) }
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "sin は実数引数のみ"))
            case ("cos", 1):
                if let r = args[0].asReal { return .real(cos(r)) }
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "cos は実数引数のみ"))
            case ("tan", 1):
                if let r = args[0].asReal { return .real(tan(r)) }
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "tan は実数引数のみ"))
            case ("exp", 1):
                if let r = args[0].asReal { return .real(exp(r)) }
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "exp は実数引数のみ"))
            case ("log", 1), ("ln", 1):
                if let r = args[0].asReal { return .real(log(r)) }
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "log は実数引数のみ"))
            default:
                throw ComplexFormulaParseError.invalidSyntax(String(localized: "未知の関数: \(name)"))
            }
        }

        // MARK: - Helpers

        func applyBinary(_ a: Value, _ op: Character, _ b: Value) -> Value {
            // どちらかが複素数なら複素演算、両方実数なら実数演算
            switch (a, b) {
            case (.real(let x), .real(let y)):
                switch op {
                case "+": return .real(x + y)
                case "-": return .real(x - y)
                case "*": return .real(x * y)
                case "/": return y == 0 ? .real(.nan) : .real(x / y)
                default: return .real(.nan)
                }
            default:
                let ac = a.asComplex, bc = b.asComplex
                switch op {
                case "+": return .complex(ac + bc)
                case "-": return .complex(ac - bc)
                case "*": return .complex(ac * bc)
                case "/": return .complex(ac / bc)
                default: return .complex(.zero)
                }
            }
        }

        func applyPower(_ base: Value, _ exp: Value) -> Value {
            switch (base, exp) {
            case (.real(let b), .real(let e)):
                return .real(pow(b, e))
            default:
                // 複素ベース ^ 整数指数 のみサポート（実用範囲）
                let bc = base.asComplex
                if case .real(let e) = exp, e == e.rounded() {
                    return .complex(bc.power(Int(e)))
                }
                return .complex(Complex(re: .nan, im: .nan))
            }
        }
    }

    private static func evaluateAsValue(_ source: String, x: Double, y: Double) throws -> Value {
        let tokens = try tokenize(source)
        guard !tokens.isEmpty else {
            throw ComplexFormulaParseError.empty
        }
        let parser = Parser(tokens: tokens, x: x, y: y)
        let v = try parser.parseExpression()
        if parser.peek != nil {
            throw ComplexFormulaParseError.invalidSyntax(String(localized: "末尾に余分なトークン"))
        }
        return v
    }
}
