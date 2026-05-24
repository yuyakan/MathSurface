//
//  Complex.swift
//  MathSurface
//
//  複素数の値型と基本演算
//

import Foundation

struct Complex: Hashable, CustomStringConvertible {
    var re: Double
    var im: Double

    init(re: Double, im: Double) {
        self.re = re
        self.im = im
    }

    static let zero = Complex(re: 0, im: 0)
    static let one = Complex(re: 1, im: 0)
    static let i = Complex(re: 0, im: 1)

    var magnitude: Double { (re * re + im * im).squareRoot() }
    var argument: Double { atan2(im, re) }
    var conjugate: Complex { Complex(re: re, im: -im) }

    static func + (a: Complex, b: Complex) -> Complex {
        Complex(re: a.re + b.re, im: a.im + b.im)
    }
    static func - (a: Complex, b: Complex) -> Complex {
        Complex(re: a.re - b.re, im: a.im - b.im)
    }
    static prefix func - (a: Complex) -> Complex {
        Complex(re: -a.re, im: -a.im)
    }
    static func * (a: Complex, b: Complex) -> Complex {
        Complex(re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re)
    }
    static func / (a: Complex, b: Complex) -> Complex {
        let denom = b.re * b.re + b.im * b.im
        guard denom > 0 else { return Complex(re: .nan, im: .nan) }
        return Complex(re: (a.re * b.re + a.im * b.im) / denom, im: (a.im * b.re - a.re * b.im) / denom)
    }

    /// 整数累乗。負の n はゼロ除算で nan を返す。
    func power(_ n: Int) -> Complex {
        if n == 0 { return .one }
        if n > 0 {
            var result = Complex.one
            for _ in 0..<n { result = result * self }
            return result
        }
        // n < 0: 1 / z^|n|
        return Complex.one / self.power(-n)
    }

    var description: String {
        if im == 0 { return formatComponent(re) }
        if re == 0 { return "\(formatComponent(im))i" }
        let sign = im >= 0 ? "+" : "-"
        return "\(formatComponent(re)) \(sign) \(formatComponent(abs(im)))i"
    }

    private func formatComponent(_ v: Double) -> String {
        if v == v.rounded() {
            return String(Int(v))
        }
        return String(format: "%g", v)
    }
}
