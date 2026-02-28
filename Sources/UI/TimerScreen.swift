import SwiftUI
import Domain
import DesignSystem

public struct TimerScreen: View {
    @ObservedObject private var viewModel: TimerViewModel
    @ObservedObject private var waterViewModel: WaterViewModel
    private let entitlement: Entitlement
    @AppStorage("atrest.vigil.enabled") private var isVigilEnabled: Bool = false

    @State private var showFastStartLine = false
    @State private var showArrivalScripture = false
    @State private var previousStatus: FastingStatus = .idle

    public init(viewModel: TimerViewModel, waterViewModel: WaterViewModel, entitlement: Entitlement) {
        self.viewModel = viewModel
        self.waterViewModel = waterViewModel
        self.entitlement = entitlement
    }

    public var body: some View {
        ZStack {
            DuskBackground().ignoresSafeArea()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content
                    .onAppear { _ = viewModel.refresh() }
                    .onChange(of: context.date) { _ in _ = viewModel.refresh() }
                    .onChange(of: viewModel.status) { _ in _ = viewModel.refresh() }
            }

            if showFastStartLine && isVigilEnabled {
                Text(VigilContentProvider.fastStartLine)
                    .font(Typography.body)
                    .foregroundStyle(Palette.accent)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .onChange(of: viewModel.isJustCompleted) { isComplete in
            if isComplete {
                if isVigilEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(Motion.scriptureFadeIn) {
                            showArrivalScripture = true
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        viewModel.isJustCompleted = false
                    }
                }
            } else {
                showArrivalScripture = false
            }
        }
        .onChange(of: viewModel.status) { newStatus in
            defer { previousStatus = newStatus }
            if case .active = newStatus, case .idle = previousStatus {
                if isVigilEnabled {
                    withAnimation(Motion.scriptureFadeIn) {
                        showFastStartLine = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
                        withAnimation(Motion.scriptureFadeOut) {
                            showFastStartLine = false
                        }
                    }
                }
            }
            if case .completed = newStatus {} else {
                showArrivalScripture = false
            }
        }
    }

    private var content: some View {
        ZStack {
            if case .active = viewModel.status, entitlement != .free {
                TreeMaterializationView(
                    variantIndex: viewModel.activeTreeVariantIndex,
                    toneIndex: viewModel.activeTreeToneIndex,
                    progress: viewModel.materializationProgress,
                    showStar: viewModel.isJustCompleted
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                if case .active = viewModel.status {
                    Text(viewModel.formattedElapsed)
                        .font(Typography.elapsed)
                        .foregroundStyle(Palette.highlight)
                        .monospacedDigit()
                        .padding(.bottom, Spacing.sm)
                }

                if let milestone = viewModel.milestone {
                    Text(viewModel.milestoneLabel)
                        .font(Typography.body)
                        .foregroundStyle(Palette.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, milestoneTextTopPadding(for: milestone))

                    if isVigilEnabled {
                        let vigilContent = VigilContentProvider.milestoneContent(for: milestone)

                        Text(vigilContent.companionAddition)
                            .font(Typography.body)
                            .foregroundStyle(Palette.accent)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.xs)
                            .transition(.opacity)
                            .animation(Motion.ease, value: milestone)

                        ScriptureFragmentView(
                            text: vigilContent.scripture.text,
                            citation: vigilContent.scripture.citation
                        )
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.lg)
                        .transition(.opacity)
                        .animation(Motion.scriptureDelayed, value: milestone)
                    }
                }

                if case .idle = viewModel.status {
                    Text(L10n.timerIdlePrompt)
                        .font(Typography.body)
                        .foregroundStyle(Palette.accent)
                        .padding(.bottom, isVigilEnabled ? Spacing.xl : Spacing.md)

                    if isVigilEnabled {
                        let fragment = VigilContentProvider.idleFragment()
                        ScriptureFragmentView(
                            text: fragment.text,
                            citation: fragment.citation
                        )
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.md)
                    }
                }

                if case .completed = viewModel.status {
                    Text(L10n.timerCompletedLabel)
                        .font(Typography.heading)
                        .foregroundStyle(Palette.highlight)
                        .padding(.bottom, Spacing.md)

                    if viewModel.isJustCompleted && showArrivalScripture && isVigilEnabled {
                        let completedCount = viewModel.completedFastCount ?? 0
                        let fragment = VigilContentProvider.arrivalFragment(fastIndex: completedCount)
                        ScriptureFragmentView(
                            text: fragment.text,
                            citation: fragment.citation
                        )
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.md)
                        .transition(.opacity)
                    }
                }

                if case .abandoned = viewModel.status {
                    Text(L10n.timerAbandonedLabel)
                        .font(Typography.heading)
                        .foregroundStyle(Palette.muted)
                        .padding(.bottom, Spacing.md)
                }

                Spacer()

                if case .active = viewModel.status {
                    WaterInlineView(viewModel: waterViewModel)
                        .padding(.bottom, Spacing.md)
                }

                Button(action: { _ = viewModel.primaryAction() }) {
                    Text(viewModel.primaryActionLabel)
                        .font(Typography.label)
                        .foregroundStyle(Palette.highlight)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .fill(Palette.surface)
                                .opacity(0.6)
                        )
                }
                .opacity(0.70)

                if case .active = viewModel.status {
                    Button(action: { _ = viewModel.abandon() }) {
                        Text(L10n.timerActionAbandon)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.muted)
                    }
                    .padding(.top, Spacing.sm)
                }

                Spacer().frame(height: Spacing.xxl)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
        }
    }

    private func milestoneTextTopPadding(for milestone: FastingMilestone) -> CGFloat {
        milestone == .digestionCompleting ? Spacing.sm : Spacing.xs
    }
}
