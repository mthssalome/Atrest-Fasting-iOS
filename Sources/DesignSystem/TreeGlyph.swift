import SwiftUI
import Domain

public struct TreeGlyph: View {
    private let memory: TreeMemory
    private let isLocked: Bool
    private let accessibilityLabel: String
    private let accessibilityHint: String

    public init(memory: TreeMemory, isLocked: Bool, accessibilityLabel: String, accessibilityHint: String) {
        self.memory = memory
        self.isLocked = isLocked
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }

    public var body: some View {
        VStack(spacing: Spacing.xs) {
            Circle()
                .fill(isLocked ? Palette.muted.opacity(0.35) : Palette.highlight.opacity(0.45))
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(Palette.stroke.opacity(isLocked ? 0.25 : 0.35), lineWidth: 1)
                )
            Capsule()
                .fill(isLocked ? Palette.muted.opacity(0.5) : Palette.accent.opacity(0.6))
                .frame(width: 6, height: 32)
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.sm)
        .background(Palette.surface.opacity(0.45))
        .cornerRadius(Radii.soft)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}
