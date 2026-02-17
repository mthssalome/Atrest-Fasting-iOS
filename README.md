# Atrest Fasting App

Scaffolded SwiftUI-first package with modular targets for Domain, Data, UI, DesignSystem, and Policy. See spec/implementation-contract.md and doctrine/* for binding implementation rules.

## Tooling
- Formatting: swift-format (config in .swift-format.json)
- Linting: SwiftLint (config in .swiftlint.yml)
- Snapshot/UI harness: pointfreeco/swift-snapshot-testing
- CI: GitHub Actions on every push (macOS runner, iOS simulator)
- Policy tests: binding enforcement aligned to spec/implementation-contract.md and doctrine/*
- Localization: Base strings in Sources/UI/Resources/Localizable.strings (loaded via Bundle.module)
- Purchases: StoreKit-driven premium (annual + lifetime) with local entitlement persistence and restore

## Running checks locally
1. `swift package resolve`
2. `swift-format lint --configuration .swift-format.json --recursive .`
3. `swiftlint`
4. `xcodebuild -scheme AtrestFastingApp-Package -destination 'platform=iOS Simulator,name=iPhone 15' -sdk iphonesimulator clean test`

## Release readiness notes (Phase 6)
- Visual snapshot baselines require Mac capture; `isRecording` is `true` until baselines are generated and committed.
- Reduce Motion is respected through `DesignSystem.Motion.ease` gating animations.
- All UI strings route through `L10n` and `Localizable.strings` to avoid hard-coded copy.
- Accessibility: key controls include labels/hints; dynamic type uses system fonts; high-contrast friendly palette.
- Data remains local by default. Uninstall deletes local data unless the user exports a backup via Settings -> Data portability.
- Purchases are handled by Apple; no accounts or tracking. Premium entitlements reconcile on launch/foreground, and Restore Purchases is available from the paywall.
- **App Store submission** requires an Xcode project (`.xcodeproj`) wrapping this package. The SPM package alone cannot produce a signed `.ipa`. Create the project with: File → New → Project → iOS App, add this package as a local dependency, and configure signing + StoreKit configuration.

## Notes
- Core utilities (timer, phases, water tracking) run locally with persisted sessions and hydration logs.
- Policy and UI snapshot tests are wired; baseline capture is controlled in the test harness.
