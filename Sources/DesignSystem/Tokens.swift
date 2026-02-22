import SwiftUI
import UIKit

// MARK: - Colour Palette (doctrine/06-apple-ux.md)

public enum Palette {
    // Sky — atmospheric background canvas
    public static let deepNight    = Color(hex: "#0D0D1A")
    public static let duskBase     = Color(hex: "#1A1225")
    public static let horizonWarm  = Color(hex: "#2D1F0E")
    public static let horizonCool  = Color(hex: "#111827")

    // Functional aliases (used by existing UI — must remain)
    public static let canvas       = deepNight
    public static let surface      = Color(red: 0.12, green: 0.10, blue: 0.14)
    public static let stroke       = Color(red: 0.30, green: 0.25, blue: 0.33)
    public static let accent       = Color(red: 0.58, green: 0.55, blue: 0.65)
    public static let muted        = Color(red: 0.45, green: 0.42, blue: 0.50)
    public static let highlight    = Color(red: 0.88, green: 0.84, blue: 0.78)

    // Earth tones — tree tonal identities (index 0–4)
    public static let earthTones: [(dark: Color, light: Color)] = [
        (Color(hex: "#3D2B1F"), Color(hex: "#7A5C45")),   // 0: bark brown
        (Color(hex: "#C17F3A"), Color(hex: "#E8A94E")),   // 1: warm amber
        (Color(hex: "#3A4A35"), Color(hex: "#6B7F5E")),   // 2: moss-grey green
        (Color(hex: "#4A4E5A"), Color(hex: "#8A909E")),   // 3: cool stone
        (Color(hex: "#8B6914"), Color(hex: "#D4A825")),   // 4: ancient gold
    ]

    // Materialization start colour (cool grey)
    public static let treeGrey = Color(red: 0.55, green: 0.55, blue: 0.60)

    // Star
    public static let starLight = Color(hex: "#F0EDE6")
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    public static func interpolate(from: Color, to: Color, t: Double) -> Color {
        let t = max(0, min(1, t))
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]
        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * t
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * t
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * t
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Typography (doctrine/06-apple-ux.md)

public enum Typography {
    public static let title = Font.system(.largeTitle, design: .rounded).weight(.semibold)
    public static let heading = Font.system(.title3, design: .rounded).weight(.semibold)
    public static let body = Font.system(.body, design: .rounded)
    public static let label = Font.system(.callout, design: .rounded).weight(.medium)
    public static let caption = Font.system(.caption, design: .rounded)
    public static let elapsed = Font.system(size: 48, weight: .light, design: .rounded)
}

// MARK: - Spacing & Radii

public enum Spacing {
    public static let xs: CGFloat = 6
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 14
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 28
    public static let xxl: CGFloat = 44
}

public enum Radii {
    public static let soft: CGFloat = 12
    public static let pill: CGFloat = 22
}

// MARK: - Motion (doctrine/06-apple-ux.md — 300-600ms, organic)

public enum Motion {
    public static var ease: Animation {
        UIAccessibility.isReduceMotionEnabled ? .none : .easeInOut(duration: 0.4)
    }
    public static var slow: Animation {
        UIAccessibility.isReduceMotionEnabled ? .none : .easeInOut(duration: 0.6)
    }
    public static var arrival: Animation {
        UIAccessibility.isReduceMotionEnabled ? .none : .easeOut(duration: 1.2)
    }
    public static var starAppear: Animation {
        UIAccessibility.isReduceMotionEnabled ? .none : .easeIn(duration: 1.2).delay(0.4)
    }
}
