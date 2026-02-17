import SwiftUI
import Domain
import DesignSystem

public struct TimerScreen: View {
    @ObservedObject private var viewModel: TimerViewModel

    public init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content
                    .onAppear { _ = viewModel.refresh() }
                    .onChange(of: context.date) { _, _ in _ = viewModel.refresh() }
                    .onChange(of: viewModel.status) { _, _ in _ = viewModel.refresh() }
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(L10n.timerTitle)
                    .font(Typography.title)
                    .foregroundStyle(Palette.highlight)
                Text(L10n.timerSubtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.muted)
            }

            VStack(spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(L10n.stateLabel)
                            .font(Typography.label)
                            .foregroundStyle(Palette.muted)
                        Text(viewModel.statusLabel)
                            .font(Typography.heading)
                            .foregroundStyle(Palette.highlight)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        Text(L10n.milestoneLabel)
                            .font(Typography.label)
                            .foregroundStyle(Palette.muted)
                        Text(viewModel.milestoneLabel)
                            .font(Typography.body)
                            .foregroundStyle(Palette.accent)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(L10n.elapsedLabel)
                        .font(Typography.label)
                        .foregroundStyle(Palette.muted)
                    Text(String(format: L10n.elapsedFormat, viewModel.durationHours))
                        .font(Typography.heading)
                        .foregroundStyle(Palette.highlight)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Palette.surface)
            .cornerRadius(Radii.soft)

            Button(viewModel.primaryActionLabel) {
                _ = viewModel.primaryAction()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Palette.accent.opacity(0.25))
            .foregroundStyle(Palette.highlight)
            .cornerRadius(Radii.pill)

            if case .active = viewModel.status {
                Button(L10n.abandon) {
                    _ = viewModel.abandon()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Palette.surface)
                .foregroundStyle(Palette.muted)
                .cornerRadius(Radii.pill)
            }

            if let notice = viewModel.trialNotice {
                Text(notice)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.muted)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Palette.surface)
                    .cornerRadius(Radii.soft)
                    .onTapGesture {
                        viewModel.trialNotice = nil
                    }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
    }
