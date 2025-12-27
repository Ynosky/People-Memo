//
//  ColorExtension.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI

extension Color {
    // MARK: - Theme Colors (Semantic Colors)
    
    /// アプリ背景色（セマンティック）
    static func appBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color(hex: "F2F2F7") // わずかにグレーがかった白
        case .dark:
            return Color(hex: "000000") // True Black（有機ELで美しい）
        @unknown default:
            return Color(hex: "F2F2F7")
        }
    }
    
    /// カード背景色（セマンティック）
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color.white
        case .dark:
            return Color(hex: "1C1C1E") // Dark Gray
        @unknown default:
            return Color.white
        }
    }
    
    /// プライマリテキスト色（セマンティック）
    static func primaryText(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color(hex: "1C1C1E") // 墨色
        case .dark:
            return Color(hex: "E5E5E7") // オフホワイト（目に優しい）
        @unknown default:
            return Color(hex: "1C1C1E")
        }
    }
    
    /// カードの枠線色（セマンティック）
    static func cardBorder(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color.primary.opacity(0.1) // 通常の枠線
        case .dark:
            return Color.white.opacity(0.1) // ダークモードでは薄い白の枠線
        @unknown default:
            return Color.primary.opacity(0.1)
        }
    }
    
    /// 墨色（柔らかい黒）- 後方互換性のため保持
    static let inkColor = Color(hex: "1C1C1E")
    
    // MARK: - Brand Colors
    
    /// プライマリアクセント（Electric Indigo）
    static let brandPrimary = Color(hex: "5856D6")
    
    /// セカンダリアクセント（Soft Coral）
    static let brandSecondary = Color(hex: "FF6B6B")
    
    /// プライマリカラー（ミントグリーン）- 後方互換性のため保持
    static let primaryMint = Color(hex: "4ECDC4")
    
    /// セカンダリカラー（サーモンピンク）- 後方互換性のため保持
    static let secondarySalmon = Color(hex: "FF6B6B")
    
    /// アクセントカラー（スカイブルー）
    static let accentSky = Color(hex: "74B9FF")
    
    /// アクセントカラー（レモンイエロー）
    static let accentLemon = Color(hex: "FFE66D")
    
    // MARK: - Person Colors (パステルビビッドカラー)
    
    static let personColors: [Color] = [
        Color(hex: "4ECDC4"), // ミントグリーン
        Color(hex: "FF6B6B"), // サーモンピンク
        Color(hex: "74B9FF"), // スカイブルー
        Color(hex: "FFE66D"), // レモンイエロー
        Color(hex: "A29BFE"), // ラベンダー
        Color(hex: "FD79A8"), // ピンク
        Color(hex: "FDCB6E"), // イエロー
        Color(hex: "6C5CE7"), // パープル
        Color(hex: "00B894"), // グリーン
        Color(hex: "E17055"), // オレンジ
    ]
    
    /// 人物のIDに基づいて一貫したカラーを返す
    static func personColor(for id: UUID) -> Color {
        let index = abs(id.hashValue) % personColors.count
        return personColors[index]
    }
    
    // MARK: - Aurora Glass Colors
    
    /// ダーク背景色（濃紺）
    static let auroraDarkBackground = Color(hex: "0A0E27")
    
    /// オーロラグラデーションカラー（鮮やかな高彩度）
    static let auroraBlue = Color(hex: "00D4FF")      // 鮮やかなシアン
    static let auroraCyan = Color(hex: "00FFE5")      // 明るいシアン
    static let auroraGreen = Color(hex: "00FF88")     // 鮮やかなグリーン
    static let auroraYellow = Color(hex: "FFE500")    // 鮮やかなイエロー
    static let auroraOrange = Color(hex: "FF6B00")    // 鮮やかなオレンジ
    static let auroraRed = Color(hex: "FF003D")       // 鮮やかな赤
    static let auroraPink = Color(hex: "FF00A8")      // 鮮やかなピンク
    static let auroraPurple = Color(hex: "9D00FF")    // 鮮やかな紫
    
    /// オーロラグラデーション配列（流動的）
    static let auroraGradientColors: [Color] = [
        auroraBlue,
        auroraCyan,
        auroraGreen,
        auroraYellow,
        auroraOrange,
        auroraRed,
        auroraPink,
        auroraPurple
    ]
    
    /// ランダムなオーロラカラーを返す
    static func randomAuroraColor() -> Color {
        auroraGradientColors.randomElement() ?? auroraBlue
    }
    
    /// インデックスに基づいてオーロラカラーを返す
    static func auroraColor(at index: Int) -> Color {
        auroraGradientColors[index % auroraGradientColors.count]
    }
    
    // MARK: - Hex Color Initializer
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

