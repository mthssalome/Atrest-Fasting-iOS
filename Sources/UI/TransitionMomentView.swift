import SwiftUI
import DesignSystem

public struct TransitionMomentView: View {
    let onContinue: () -> Void
    let onDismiss: () -> Void

    public init(onContinue: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            DuskBackground().ignoresSafeArea()
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Image(systemName: "leaf.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Palette.highlight)
                    .padding(.top, Spacing.xl)

                Text(L10n.transitionBody)
                    .font(Typography.body)
                    .foregroundStyle(Palette.highlight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                VStack(spacing: Spacing.md) {
                    Button(action: onContinue) {
                        Text(L10n.transitionContinue)
                            .font(Typography.label)
                            .foregroundStyle(Palette.highlight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Radii.soft)
                                    .fill(Palette.surface.opacity(0.7))
                            )
                    }
                    Button(action: onDismiss) {
                        Text(L10n.transitionLater)
                            .font(Typography.label)
                            .foregroundStyle(Palette.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Radii.soft)
                                    .fill(Palette.surface.opacity(0.5))
                            )
                    }
                }
                .padding(.horizontal, Spacing.xl)

                Spacer()
            }
            .padding(.top, Spacing.xl)
        }
    }
}
