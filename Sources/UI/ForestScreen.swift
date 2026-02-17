import SwiftUI
import Domain
import DesignSystem

public struct ForestScreen: View {
    @ObservedObject private var viewModel: ForestViewModel

    public init(viewModel: ForestViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(L10n.forestTitle)
                        .font(Typography.title)
                        .foregroundStyle(Palette.highlight)
                        .padding(.bottom, Spacing.xs)
                    Text(L10n.forestSubtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3), spacing: Spacing.sm) {
                        ForEach(viewModel.trees) { tree in
                            TreeGlyph(
                                memory: tree.memory,
                                isLocked: tree.isLocked,
                                accessibilityLabel: tree.isLocked ? L10n.lockedTreeAccessibility : L10n.unlockedTreeAccessibility,
                                accessibilityHint: L10n.treeHint
                            )
                                .animation(Motion.ease, value: viewModel.trees.map { $0.id })
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
            }
        }
    }
}

#Preview {
    ForestScreen(viewModel: ForestViewModel(historyItems: []))
}
