import SwiftUI
import DesignSystem

public struct ScriptureFragmentView: View {
    let text: String
    let citation: String

    @State private var showCitation = false

    public init(text: String, citation: String) {
        self.text = text
        self.citation = citation
    }

    public var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(text)
                .font(Typography.scripture)
                .tracking(1.2)
                .foregroundStyle(Palette.scriptureText)
                .multilineTextAlignment(.center)
                .accessibilityLabel(String(format: L10n.vigilA11yScripture, text))

            if showCitation {
                Text(citation)
                    .font(Typography.citation)
                    .tracking(1.6)
                    .foregroundStyle(Palette.citationText)
                    .transition(.opacity)
                    .accessibilityLabel(String(format: L10n.vigilA11yCitation, citation))
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation(Motion.citationReveal) {
                showCitation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                withAnimation(Motion.citationDismiss) {
                    showCitation = false
                }
            }
        }
    }
}
