import SwiftUI
import Domain
import DesignSystem

public struct FloatingNavIcons: View {
    let entitlement: Entitlement
    let onForest: () -> Void
    let onCalendar: () -> Void
    let onSettings: () -> Void

    public init(entitlement: Entitlement, onForest: @escaping () -> Void, onCalendar: @escaping () -> Void, onSettings: @escaping () -> Void) {
        self.entitlement = entitlement
        self.onForest = onForest
        self.onCalendar = onCalendar
        self.onSettings = onSettings
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack(spacing: Spacing.xxl) {
                if entitlement != .free {
                    Button(action: onForest) {
                        Image(systemName: "leaf")
                            .font(.title3)
                            .foregroundStyle(Palette.muted)
                            .accessibilityLabel(L10n.navA11yForest)
                    }
                }
                Button(action: onCalendar) {
                    Image(systemName: "circle.grid.3x3")
                        .font(.title3)
                        .foregroundStyle(Palette.muted)
                        .accessibilityLabel(L10n.navA11yCalendar)
                }
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundStyle(Palette.muted)
                        .accessibilityLabel(L10n.navA11ySettings)
                }
            }
            .opacity(0.40)
            .padding(.bottom, Spacing.xl)
        }
        .allowsHitTesting(true)
    }
}
