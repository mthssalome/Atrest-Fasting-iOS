import SwiftUI
import UIKit

public enum Palette {
    public static let canvas = Color(red: 0.07, green: 0.08, blue: 0.09)
    public static let surface = Color(red: 0.12, green: 0.13, blue: 0.14)
    public static let stroke = Color(red: 0.30, green: 0.33, blue: 0.36)
    public static let accent = Color(red: 0.58, green: 0.67, blue: 0.71)
    public static let muted = Color(red: 0.45, green: 0.50, blue: 0.54)
    public static let highlight = Color(red: 0.72, green: 0.78, blue: 0.80)
}

public enum Typography {
    public static let title = Font.system(.largeTitle, design: .rounded).weight(.semibold)
    public static let heading = Font.system(.title3, design: .rounded).weight(.semibold)
    public static let body = Font.system(.body, design: .rounded)
    public static let label = Font.system(.callout, design: .rounded).weight(.medium)
    public static let caption = Font.system(.caption, design: .rounded)
}

public enum Spacing {
    public static let xs: CGFloat = 6
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 14
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 28
}

public enum Radii {
    public static let soft: CGFloat = 12
    public static let pill: CGFloat = 22
}

public enum Motion {
    public static var ease: Animation {
        UIAccessibility.isReduceMotionEnabled ? .none : .easeInOut(duration: 0.2)
    }
}
