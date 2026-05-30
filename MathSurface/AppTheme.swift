//
//  AppTheme.swift
//  MathSurface
//
//  ダーク・ネオン系のアプリ全体テーマ
//

import SwiftUI

enum AppTheme {
    /// メイン背景（チャコール）
    static let background = Color(red: 0.102, green: 0.122, blue: 0.180)  // #1A1F2E
    /// アクセント1（メイン）: シアン
    static let accent = Color(red: 0.0, green: 0.898, blue: 1.0)  // #00E5FF
    /// アクセント2（強調）: ライムグリーン
    static let accentLime = Color(red: 0.659, green: 1.0, blue: 0.0)  // #A8FF00
    /// アクセント3（比較/警告）: ホットピンク
    static let accentPink = Color(red: 1.0, green: 0.176, blue: 0.529)  // #FF2D87

    /// 背景グラデーション（チャコール）
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.102, green: 0.122, blue: 0.180),
                Color(red: 0.140, green: 0.165, blue: 0.231)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
