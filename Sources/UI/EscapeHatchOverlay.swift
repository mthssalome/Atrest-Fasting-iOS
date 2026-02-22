import SwiftUI
import Domain
import DesignSystem

public struct EscapeHatchOverlay: View {
    let entitlement: Entitlement
    let onForest: () -> Void
    let onCalendar: () -> Void
    let onSettings: () -> Void
    @State private var isExpanded = false

    public init(entitlement: Entitlement, onForest: @escaping () -> Void, onCalendar: @escaping () -> Void, onSettings: @escaping () -> Void) {
        self.entitlement = entitlement
        self.onForest = onForest
        self.onCalendar = onCalendar
        self.onSettings = onSettings
    }

    public var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation(Motion.ease) { isExpanded.toggle() }
                } label: {
                    Image(systemName: "leaf.circle")
                        .font(.title2)
                        .foregroundStyle(Palette.muted)
                        .opacity(0.30)
                        .accessibilityLabel(L10n.navA11yEscape)
                }
                .padding(.leading, Spacing.lg)
                .padding(.top, Spacing.lg)
                Spacer()
            }
            Spacer()
        }
        .overlay {
            if isExpanded {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(Motion.ease) { isExpanded = false } }

                    VStack(spacing: Spacing.xl) {
                        if entitlement != .free {
                            Button {
                                isExpanded = false
                                onForest()
                            } label: {
                                Image(systemName: "leaf")
                                    .font(.title)
                                    .foregroundStyle(Palette.highlight)
                                    .accessibilityLabel(L10n.navA11yForest)
                            }
                        }
                        Button {
                            isExpanded = false
                            onCalendar()
                        } label: {
                            Image(systemName: "circle.grid.3x3")
                                .font(.title)
                                .foregroundStyle(Palette.highlight)
                                .accessibilityLabel(L10n.navA11yCalendar)
                        }
                        Button {
                            isExpanded = false
                            onSettings()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.title)
                                .foregroundStyle(Palette.highlight)
                                .accessibilityLabel(L10n.navA11ySettings)
                        }
                    }
                    .padding(Spacing.xl)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radii.soft))
                }
                .transition(.opacity)
            }
        }
    }
}
