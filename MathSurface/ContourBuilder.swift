//
//  ContourBuilder.swift
//  MathSurface
//
//  Marching Squares による等高線（z = c）抽出
//

import Foundation

enum ContourBuilder {
    /// 関数 f(x, y) の等高線 f = level を、与えられた xy 矩形内のグリッドから抽出する。
    /// 結果は「線分の集合」。各線分は (始点, 終点) の2D座標。
    static func contourSegments(
        f: (Double, Double) -> Double,
        xRange: ClosedRange<Double>,
        yRange: ClosedRange<Double>,
        level: Double,
        resolution: Int = 80
    ) -> [(start: (x: Double, y: Double), end: (x: Double, y: Double))] {
        let n = max(2, resolution)
        let xStep = (xRange.upperBound - xRange.lowerBound) / Double(n)
        let yStep = (yRange.upperBound - yRange.lowerBound) / Double(n)

        // 値を全グリッドで事前計算
        var grid = Array(repeating: Array(repeating: 0.0, count: n + 1), count: n + 1)
        for i in 0...n {
            let x = xRange.lowerBound + Double(i) * xStep
            for j in 0...n {
                let y = yRange.lowerBound + Double(j) * yStep
                grid[i][j] = f(x, y)
            }
        }

        var segments: [(start: (x: Double, y: Double), end: (x: Double, y: Double))] = []

        for i in 0..<n {
            for j in 0..<n {
                let x0 = xRange.lowerBound + Double(i) * xStep
                let y0 = yRange.lowerBound + Double(j) * yStep
                let x1 = x0 + xStep
                let y1 = y0 + yStep

                let v00 = grid[i][j]     // (x0, y0)
                let v10 = grid[i+1][j]   // (x1, y0)
                let v01 = grid[i][j+1]   // (x0, y1)
                let v11 = grid[i+1][j+1] // (x1, y1)

                // どれかが NaN/Inf ならスキップ
                if !v00.isFinite || !v10.isFinite || !v01.isFinite || !v11.isFinite { continue }

                // 各頂点が level 以上かを bit で表現（左下=bit0, 右下=bit1, 右上=bit2, 左上=bit3）
                var code = 0
                if v00 >= level { code |= 1 }
                if v10 >= level { code |= 2 }
                if v11 >= level { code |= 4 }
                if v01 >= level { code |= 8 }

                if code == 0 || code == 15 { continue }

                // 4辺上の交点（線形補間）
                func interp(_ vA: Double, _ vB: Double, _ pA: (x: Double, y: Double), _ pB: (x: Double, y: Double)) -> (x: Double, y: Double) {
                    let denom = vB - vA
                    let t = abs(denom) < 1e-12 ? 0.5 : (level - vA) / denom
                    let clamped = max(0, min(1, t))
                    return (pA.x + (pB.x - pA.x) * clamped, pA.y + (pB.y - pA.y) * clamped)
                }

                let bottom = interp(v00, v10, (x0, y0), (x1, y0))
                let right  = interp(v10, v11, (x1, y0), (x1, y1))
                let top    = interp(v01, v11, (x0, y1), (x1, y1))
                let left   = interp(v00, v01, (x0, y0), (x0, y1))

                // ケースごとに線分追加
                switch code {
                case 1, 14:  segments.append((bottom, left))
                case 2, 13:  segments.append((bottom, right))
                case 3, 12:  segments.append((left, right))
                case 4, 11:  segments.append((top, right))
                case 6, 9:   segments.append((bottom, top))
                case 7, 8:   segments.append((left, top))
                case 5:
                    // 鞍点ケース: 4頂点の平均で分岐
                    let center = (v00 + v10 + v01 + v11) / 4
                    if (center >= level) == (v00 >= level) {
                        segments.append((left, bottom))
                        segments.append((right, top))
                    } else {
                        segments.append((left, top))
                        segments.append((right, bottom))
                    }
                case 10:
                    let center = (v00 + v10 + v01 + v11) / 4
                    if (center >= level) == (v10 >= level) {
                        segments.append((bottom, right))
                        segments.append((left, top))
                    } else {
                        segments.append((bottom, left))
                        segments.append((right, top))
                    }
                default: break
                }
            }
        }
        return segments
    }
}
