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
            DuskBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    productStack
                    reassurance
                    footer
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.xl)
            }
        }
        .task { await viewModel.loadProducts() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(L10n.paywallValues)
                .font(Typography.title)
                .foregroundStyle(Palette.highlight)
            Text(L10n.paywallDescription)
                .font(Typography.body)
                .foregroundStyle(Palette.muted)
        }
    }

    private var productStack: some View {
        VStack(spacing: Spacing.md) {
            productCard(title: L10n.paywallAnnual, product: .annual)
            productCard(title: L10n.paywallLifetime, product: .lifetime)
        }
    }

    private func productCard(title: String, product: PurchaseProduct) -> some View {
        Button {
            Task { await viewModel.purchase(product) }
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.heading)
                    .foregroundStyle(Palette.highlight)
                Text(viewModel.price(for: product))
                    .font(Typography.body)
                    .foregroundStyle(Palette.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(Palette.surface.opacity(0.8))
            .cornerRadius(Radii.soft)
        }
        .buttonStyle(.plain)
    }

    private var reassurance: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(L10n.paywallAppleNote)
                .font(Typography.caption)
                .foregroundStyle(Palette.muted)
            Text(L10n.paywallRenewalNote)
                .font(Typography.caption)
                .foregroundStyle(Palette.muted)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Button(L10n.paywallRestore) {
                    Task { await viewModel.restore() }
                }
                .font(Typography.body)
                .foregroundStyle(Palette.accent)

                Spacer()

                Text(viewModel.statusText)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.muted)
            }

            HStack(spacing: Spacing.md) {
                if let termsURL = URL(string: L10n.paywallTermsURL) {
                    Link(L10n.paywallTerms, destination: termsURL)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.accent)
                }
                if let privacyURL = URL(string: L10n.paywallPrivacyURL) {
                    Link(L10n.paywallPrivacy, destination: privacyURL)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.accent)
                }
            }
        }
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
