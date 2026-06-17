import SwiftUI
import UIKit

enum Theme {
    // MARK: - Color Palette (Modern Serene Blue)

    enum Colors {
        // Primary brand color
        static let healthBlue = Color(hex: "3E7BFA")

        // Semantic status colors (muted, not garish)
        static let success = Color(hex: "48BB78")        // HealingGreen
        static let danger  = Color(hex: "F56565")        // SoftRed
        static let warning = Color(hex: "ED8936")        // Amber

        // Risk level colors (tinted, calm)
        static let highRisk   = Color(hex: "E53E3E")    // deep red
        static let mediumRisk = Color(hex: "D69E2E")    // deep amber
        static let lowRisk    = healthBlue

        // Light tinted backgrounds for risk cards
        static let highRiskBg   = Color(hex: "FFF5F5")
        static let mediumRiskBg = Color(hex: "FFFBEB")
        static let lowRiskBg    = Color(hex: "EBF8FF")

        // Chip / pill tag colors
        static let takenBg  = Color(hex: "E6FFFA")
        static let takenFg = Color(hex: "2C7A7B")

        // Text hierarchy - supports dark mode
        static let primaryText = Color("PrimaryText")
        static let secondaryText = Color("SecondaryText")

        // Surface layers - uses system colors for automatic dark mode
        static let background      = Color(uiColor: .systemBackground)
        static let cardBackground  = Color(uiColor: .secondarySystemGroupedBackground)
        static let tertiaryBg      = Color(uiColor: .tertiarySystemGroupedBackground)

        // Remaining text levels
        static let tertiaryText  = Color(uiColor: .tertiaryLabel)
        static let quaternaryText = Color(uiColor: .quaternaryLabel)

        // iOS design: gray tones
        static let iosGray = Color(hex: "8E8E93")
        static let iosDarkGray = Color(hex: "1C1C1E")

        // Transparent overlays
        static let glassOverlay = Color(uiColor: .systemBackground).opacity(0.72)
    }

    // MARK: - Color Assets for Dynamic Colors

    static func adaptivePrimaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "F5F5F5") : Color(hex: "1A202C")
    }

    static func adaptiveSecondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "A0AEC0") : Color(hex: "718096")
    }

    static func adaptiveCardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color(uiColor: .secondarySystemGroupedBackground)
    }

    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "000000") : Color(uiColor: .systemGroupedBackground)
    }

    static func adaptiveRiskBackground(for colorScheme: ColorScheme, risk: RiskLevel) -> Color {
        switch risk {
        case .high:
            return colorScheme == .dark ? Color(hex: "2D1B1B") : Color(hex: "FFF5F5")
        case .medium:
            return colorScheme == .dark ? Color(hex: "2D2517") : Color(hex: "FFFBEB")
        case .low:
            return colorScheme == .dark ? Color(hex: "1A2634") : Color(hex: "EBF8FF")
        }
    }

    // MARK: - Typography

    enum Typography {
        // Large Title uses SF Pro Rounded on iOS automatically
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1    = Font.title.weight(.bold)
        static let title2    = Font.title2.weight(.bold)
        static let title3    = Font.title3.weight(.semibold)
        static let headline  = Font.headline.weight(.semibold)
        static let body      = Font.body
        static let subheadline = Font.subheadline
        static let footnote  = Font.footnote
        static let caption1  = Font.caption
        static let caption2  = Font.caption2

        // iOS-specific: time display (SF Pro Rounded heavy)
        static let timeDisplay = Font.system(size: 32, weight: .heavy, design: .rounded)
        static let subtitleLight = Font.subheadline.weight(.regular)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small:      CGFloat = 8
        static let medium:     CGFloat = 12
        static let large:      CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let card:       CGFloat = 22   // iOS continuous-radius card
        static let capsule:    CGFloat = 50    // pill shape
    }

    // MARK: - Shadows (iOS-style: very subtle, Y:4 Blur:20 Opacity:0.05)

    enum Shadow {
        static let card   = ShadowStyle(color: .black.opacity(0.05), radius: 20, x: 0, y: 4)
        static let raised = ShadowStyle(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)
        static let subtle = ShadowStyle(color: .black.opacity(0.04), radius: 6,  x: 0, y: 2)
    }

    // MARK: - Animation

    enum Animation {
        static let spring  = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.82)
        static let bouncy  = SwiftUI.Animation.spring(response: 0.30, dampingFraction: 0.60)
        static let smooth  = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let snappy  = SwiftUI.Animation.spring(response: 0.28, dampingFraction: 0.70)
    }

    // MARK: - String Constants

    enum Strings {
        static let uncategorized = "未分类"
    }

    // MARK: - Date Formatters

    enum DateFormats {
        private static let timeFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f
        }()

        private static let shortDateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MM-dd"
            return f
        }()

        private static let shortDateTimeFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MM-dd HH:mm"
            return f
        }()

        private static let monthDayFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MM月dd日"
            return f
        }()

        private static let monthDayWeekdayFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "M月d日 E"
            return f
        }()

        static func timeString(from date: Date) -> String {
            timeFormatter.string(from: date)
        }

        static func shortDateString(from date: Date) -> String {
            shortDateFormatter.string(from: date)
        }

        static func shortDateTimeString(from date: Date) -> String {
            shortDateTimeFormatter.string(from: date)
        }

        static func monthDayString(from date: Date) -> String {
            monthDayFormatter.string(from: date)
        }

        static func monthDayWeekdayString(from date: Date) -> String {
            monthDayWeekdayFormatter.string(from: date)
        }
    }

    // MARK: - Haptics

    enum Haptics {
        static func success() {
            let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success)
        }
        static func warning() {
            let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.warning)
        }
        static func light() {
            let g = UIImpactFeedbackGenerator(style: .light); g.impactOccurred()
        }
        static func medium() {
            let g = UIImpactFeedbackGenerator(style: .medium); g.impactOccurred()
        }
        static func rigid() {
            let g = UIImpactFeedbackGenerator(style: .rigid); g.impactOccurred()
        }
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func cardShadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
