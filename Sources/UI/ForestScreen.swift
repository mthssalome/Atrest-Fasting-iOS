import SwiftUI
import Domain
import DesignSystem

public struct ForestScreen: View {
    @ObservedObject private var viewModel: ForestViewModel
    private let onBack: () -> Void
    @State private var scrollOffset: CGFloat = 0

    public init(viewModel: ForestViewModel, onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onBack = onBack
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            DuskBackground().ignoresSafeArea()

            if viewModel.treeLayouts.isEmpty {
                VStack {
                    Spacer()
                    Text(L10n.forestEmpty)
                        .font(Typography.body)
                        .foregroundStyle(Palette.accent)
                        .padding()
                    Spacer()
                }
            } else {
                GeometryReader { proxy in
                    let canvasHeight = Self.canvasHeight(for: viewModel.treeLayouts.count, screenHeight: proxy.size.height)
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            GeometryReader { geo in
                                Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("forestScroll")).minY)
                            }
                            .frame(height: 0)

                            starLayer(width: proxy.size.width, height: canvasHeight)
                                .offset(y: -scrollOffset * 0.70)

                            treeLayer(width: proxy.size.width, height: canvasHeight)
                        }
                        .frame(height: canvasHeight)
                    }
                    .coordinateSpace(name: "forestScroll")
                    .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
                }
            }

            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(Palette.muted)
                    .padding(Spacing.lg)
            }
            .accessibilityLabel(L10n.navA11yEscape)
        }
        .gesture(DragGesture().onEnded { gesture in
            if gesture.translation.width > 40 { onBack() }
        })
    }

    private func treeLayer(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(viewModel.treeLayouts) { layout in
                let depth = layout.depthLayer % 3
                let size: CGFloat = depth == 0 ? 80 : (depth == 1 ? 62 : 48)
                let opacity: Double = depth == 0 ? 1.0 : (depth == 1 ? 0.65 : 0.40)
                TreeView(
                    variantIndex: layout.variantIndex,
                    toneIndex: layout.toneIndex,
                    progress: layout.stateProgress,
                    isIncomplete: layout.memory.state == .incomplete,
                    size: size
                )
                .opacity(opacity)
                .position(x: layout.position.x * width, y: layout.position.y * height)
                .accessibilityLabel(layout.memory.state == .incomplete ? L10n.forestA11yTreeIncomplete : L10n.forestA11yTreeComplete)
            }
        }
    }

    private func starLayer(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(viewModel.starLayouts) { star in
                let depth = star.depthLayer % 3
                let opacity: Double = depth == 0 ? 1.0 : (depth == 1 ? 0.6 : 0.4)
                StarView()
                    .frame(width: 14, height: 14)
                    .opacity(opacity)
                    .position(x: star.position.x * width, y: star.position.y * height)
                    .accessibilityLabel(L10n.forestA11yStar)
            }
        }
    }

    private static func canvasHeight(for treeCount: Int, screenHeight: CGFloat) -> CGFloat {
        let minCanvasHeight = screenHeight * 1.5
        let growthPerTree: CGFloat = 35
        return max(minCanvasHeight, CGFloat(treeCount) * growthPerTree + screenHeight * 0.5)
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
