import SwiftUI
import Data
import DesignSystem

public struct PaywallScreen: View {
    @ObservedObject private var viewModel: PaywallViewModel

    public init(viewModel: PaywallViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(L10n.paywallTitle)
                        .font(Typography.title)
                        .foregroundStyle(Palette.highlight)
                    Text(L10n.paywallSubtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)
                }

                VStack(spacing: Spacing.sm) {
                    paywallRow(title: L10n.paywallAnnual, product: .annual)
                    paywallRow(title: L10n.paywallLifetime, product: .lifetime)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(L10n.paywallPrivacy)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)
                    Text(L10n.paywallLocalOnly)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)
                    Text(L10n.paywallRenewal)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)
                    HStack(spacing: Spacing.md) {
                        if let termsURL = URL(string: L10n.paywallTermsURL) {
                            Link(L10n.paywallTerms, destination: termsURL)
                                .font(Typography.caption)
                                .foregroundStyle(Palette.accent)
                        }
                        if let privacyURL = URL(string: L10n.paywallPrivacyURL) {
                            Link(L10n.paywallPrivacyLink, destination: privacyURL)
                                .font(Typography.caption)
                                .foregroundStyle(Palette.accent)
                        }
                    }
                }

                HStack {
                    Button(L10n.paywallRestore) {
                        Task { await viewModel.restore() }
                    }
                    .foregroundStyle(Palette.accent)
                    Spacer()
                    Text(viewModel.statusText)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)
        }
        .task { await viewModel.loadProducts() }
    }

    private func paywallRow(title: String, product: PurchaseProduct) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.heading)
                    .foregroundStyle(Palette.highlight)
                Text(viewModel.price(for: product))
                    .font(Typography.body)
                    .foregroundStyle(Palette.accent)
            }
            Spacer()
            Button(L10n.paywallSelect) {
                Task { await viewModel.purchase(product) }
            }
            .foregroundStyle(Palette.highlight)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Palette.surface)
        .cornerRadius(Radii.soft)
    }
}

#Preview {
    PaywallScreen(viewModel: PaywallViewModel(entitlementService: StaticEntitlementService(), purchaseClient: PreviewPurchaseClient()))
}

private struct PreviewPurchaseClient: PurchaseClient {
    func products(ids: [String]) async throws -> [StoreProductInfo] { ids.compactMap { id in
        guard let product = PurchaseProduct(rawValue: id) else { return nil }
        switch product {
        case .annual:
            return StoreProductInfo(id: id, displayName: "Annual", displayPrice: "$29.99")
        case .lifetime:
            return StoreProductInfo(id: id, displayName: "Lifetime", displayPrice: "$69.99")
        }
    } }
    func purchase(productID: String) async throws -> PurchaseOutcome { .purchased(productID: productID) }
    func restoreEntitlements(productIDs: [String]) async throws -> PurchaseOutcome { .notFound }
    func currentEntitlement(productIDs: [String]) async throws -> PurchaseOutcome { .notFound }
}
