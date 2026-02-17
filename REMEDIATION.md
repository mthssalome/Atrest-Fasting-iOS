# Remediation Instructions — Atrest Fasting App

**Purpose:** Deterministic, unambiguous instructions for closing every remaining
audit finding. Each task specifies the exact file, the exact code to find, and the
exact replacement. No interpretation is needed.

**Rules for the implementing agent:**

1. Apply each task in order (TASK-1 through TASK-11).
2. Do NOT rename, move, or delete any file unless explicitly instructed.
3. Do NOT refactor surrounding code. Change only the lines specified.
4. After all tasks, run `swift build` (or `xcodebuild build`) and `swift test` to
   confirm zero compile errors and zero test failures (except snapshot tests which
   require a Mac baseline capture — see TASK-2).
5. Do NOT mark any task complete until you have verified the change compiles.

---

## TASK-1 — Fix `reconcile()` enum comparison (CRITICAL — N-01 / C-05)

**File:** `Sources/Data/Entitlements.swift`

**Problem:** `PurchaseOutcome.purchased` has an associated value `(productID: String)`.
The current code compares `Optional<PurchaseOutcome>` against `.purchased` using
`==`, which is invalid Swift — enum cases with associated values cannot be compared
with `==` without providing the full associated value.

**Find this exact code** (inside the `reconcile()` method of `EntitlementService`):

```swift
    public func reconcile() async -> EntitlementSnapshot {
        let outcome = try? await purchaseClient.currentEntitlement(productIDs: productIDs)
        let purchaseEntitlement: Entitlement = (outcome == .purchased) ? .premium : .free
        if purchaseEntitlement == .premium {
            store.save(.premium)
        } else {
            store.save(.free)
        }
        let count = await completedCount()
        return effectiveSnapshot(purchaseEntitlement: purchaseEntitlement, source: .reconcile, completedCount: count)
    }
```

**Replace with:**

```swift
    public func reconcile() async -> EntitlementSnapshot {
        let outcome = try? await purchaseClient.currentEntitlement(productIDs: productIDs)
        let isPurchased: Bool
        if case .purchased = outcome {
            isPurchased = true
        } else {
            isPurchased = false
        }
        let purchaseEntitlement: Entitlement = isPurchased ? .premium : .free
        if purchaseEntitlement == .premium {
            store.save(.premium)
        } else {
            store.save(.free)
        }
        let count = await completedCount()
        return effectiveSnapshot(purchaseEntitlement: purchaseEntitlement, source: .reconcile, completedCount: count)
    }
```

**Why pattern matching works:** `if case .purchased = outcome` uses Swift pattern
matching, which ignores associated values. This is exactly how the `purchase()` and
`restore()` methods already work (via `switch/case .purchased:`).

**Verify:** After this change, `swift build` must succeed. If it did not compile
before, this was the cause.

---

## TASK-2 — Generate snapshot baselines (HIGH — N-02 / M-09)

**File:** `Tests/SnapshotTests/UIScreenSnapshotTests.swift`  
**File:** `Tests/SnapshotTests/SnapshotHarnessTests.swift`  
**Directory:** `Tests/SnapshotTests/__Snapshots__/`

**Problem:** `isRecording = false` but `__Snapshots__/` contains only `.gitkeep`.
Every snapshot test fails because there is no baseline to compare against.

**Step 2a — Temporarily set `isRecording = true`:**

In `Tests/SnapshotTests/UIScreenSnapshotTests.swift`, find:

```swift
    override func setUp() {
        super.setUp()
        isRecording = false
    }
```

Replace with:

```swift
    override func setUp() {
        super.setUp()
        isRecording = true
    }
```

Do the same in `Tests/SnapshotTests/SnapshotHarnessTests.swift` if it also sets
`isRecording = false`.

**Step 2b — Run the snapshot tests on a Mac:**

```bash
xcodebuild test \
  -scheme AtrestFastingApp-Package \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -sdk iphonesimulator \
  -only-testing:SnapshotTests
```

This will generate `.txt` reference files inside
`Tests/SnapshotTests/__Snapshots__/UIScreenSnapshotTests/` and
`Tests/SnapshotTests/__Snapshots__/SnapshotHarnessTests/`.

**Step 2c — Set `isRecording` back to `false`:**

Revert both files so `setUp()` reads:

```swift
    override func setUp() {
        super.setUp()
        isRecording = false
    }
```

**Step 2d — Commit the baselines:**

```bash
git add Tests/SnapshotTests/__Snapshots__/
git commit -m "chore: commit snapshot baselines"
```

**Verify:** Re-run the snapshot tests. All should pass (green).

**Important:** If you cannot run tests on a Mac simulator (e.g., you are in a
headless Linux environment), you must leave `isRecording = true` and add a
code comment `// TODO: Set to false after baseline capture on Mac` in both files.
Do NOT leave `isRecording = false` without baselines — that causes guaranteed
failures.

---

## TASK-3 — Fix `.swiftlint.yml` (LOW — N-08 / L-03)

**File:** `.swiftlint.yml`

**Problem:** The config uses `whitelist_rules` (deprecated, and it disables hundreds
of default rules). It should use the default rule set with minimal exclusions.

**Find this exact content:**

```yaml
included:
  - Sources
  - Tests

analyzer_rules:
  - unused_declaration
  - unused_import

reporter: "xcode"

whitelist_rules:
  - line_length
  - file_length
  - function_body_length
  - type_body_length
  - trailing_whitespace
```

**Replace with this exact content:**

```yaml
included:
  - Sources
  - Tests

analyzer_rules:
  - unused_declaration
  - unused_import

reporter: "xcode"

disabled_rules:
  - identifier_name
  - nesting
  - type_name

line_length:
  warning: 150
  error: 200

file_length:
  warning: 500
  error: 1000

function_body_length:
  warning: 60
  error: 100

type_body_length:
  warning: 300
  error: 500
```

**Why:** This uses the standard SwiftLint rule set (all default rules enabled) and
only disables three rules that conflict with the project's naming conventions.
Thresholds for length rules are set to reasonable values. The deprecated
`whitelist_rules` key is removed entirely.

---

## TASK-4 — Fix deprecated `onChange` in TimerScreen (LOW — N-05 / L-08)

**File:** `Sources/UI/TimerScreen.swift`

**Problem:** The `.onChange` calls use the single-parameter closure form, which is
deprecated in iOS 17 (the app's minimum deployment target).

**Find this exact code:**

```swift
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content
                    .onAppear { _ = viewModel.refresh() }
                    .onChange(of: context.date) { _ in _ = viewModel.refresh() }
                    .onChange(of: viewModel.status) { _ in _ = viewModel.refresh() }
            }
```

**Replace with:**

```swift
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content
                    .onAppear { _ = viewModel.refresh() }
                    .onChange(of: context.date) { _, _ in _ = viewModel.refresh() }
                    .onChange(of: viewModel.status) { _, _ in _ = viewModel.refresh() }
            }
```

**What changed:** `{ _ in` → `{ _, _ in` (two parameters: old value and new value).

---

## TASK-5 — Surface trial notice on Timer screen (MEDIUM — N-04 / C-04)

**Problem:** The contract requires "one non-intrusive notice at completion" of
fast 11. Currently, `RootView.updateDerivedData()` sets
`paywallViewModel.statusText`, but the user is on the Timer screen at that moment
and never sees it.

### Step 5a — Add a published property to `TimerViewModel`

**File:** `Sources/UI/TimerViewModel.swift`

**Find this code near the top of the class:**

```swift
@MainActor
public final class TimerViewModel: ObservableObject {
    @Published public private(set) var status: FastingStatus

    private var machine: FastingSessionMachine
```

**Replace with:**

```swift
@MainActor
public final class TimerViewModel: ObservableObject {
    @Published public private(set) var status: FastingStatus
    @Published public var trialNotice: String?

    private var machine: FastingSessionMachine
```

### Step 5b — Show the notice on TimerScreen

**File:** `Sources/UI/TimerScreen.swift`

**Find this code at the end of the `content` computed property:**

```swift
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

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
```

**Replace with:**

```swift
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
```

### Step 5c — Wire the notice from RootView

**File:** `Sources/UI/RootView.swift`

**Find this code inside `updateDerivedData`:**

```swift
        if TrialPolicy.isNoticeDue(completed: state.completedCount) && effectiveEntitlement != .premium {
            paywallViewModel.setStatusMessage(L10n.paywallTrialNotice)
    }
```

**Replace with:**

```swift
        if TrialPolicy.isNoticeDue(completed: state.completedCount) && effectiveEntitlement != .premium {
            paywallViewModel.setStatusMessage(L10n.paywallTrialNotice)
            timerViewModel.trialNotice = L10n.paywallTrialNotice
        }
```

**Note:** Also fix the indentation — the closing `}` above has incorrect
indentation (should be 8 spaces, matching the `if`). Make sure the closing `}`
aligns with the `if`.

---

## TASK-6 — Change paywall URLs to HTTPS (LOW — N-06)

**File:** `Sources/UI/Resources/Localizable.strings`

**Find these two lines:**

```
"paywall.terms.url" = "http://atrest.app/terms";
"paywall.privacy.url" = "http://atrest.app/privacy";
```

**Replace with:**

```
"paywall.terms.url" = "https://atrest.app/terms";
"paywall.privacy.url" = "https://atrest.app/privacy";
```

---

## TASK-7 — Fix README stale `isRecording` claim (LOW — N-07 / L-10)

**File:** `README.md`

**Find this text:**

```
- Visual snapshot lock-in is deferred until Mac review; `isRecording` remains `true` in snapshot tests per directive.
```

**Replace with:**

```
- Visual snapshot baselines are committed under `Tests/SnapshotTests/__Snapshots__/`; `isRecording` is `false` in all snapshot tests.
```

If TASK-2 could not be completed (no Mac available), replace with:

```
- Visual snapshot baselines require Mac capture; `isRecording` is `true` until baselines are generated and committed.
```

---

## TASK-8 — Address experimental SPM app target (HIGH — N-03 / H-03)

**Problem:** `.iOSApplication` in `Package.swift` is an experimental SPM feature.
There is no `Info.plist`, no signing config, no StoreKit configuration file, and no
entitlements file. The app cannot be archived for App Store submission.

**This task has two options. Pick Option A if possible, otherwise Option B.**

### Option A — Create an Xcode project wrapper (preferred)

This cannot be done by code generation alone. The implementing agent should:

1. Open the package in Xcode.
2. Use File → New → Project → iOS App (SwiftUI lifecycle).
3. Set Bundle Identifier to `app.atrest.fasting`.
4. Add the SPM package as a local dependency.
5. Import and wire `AtrestApp` (from `Sources/App/AtrestApp.swift`) as the `@main`
   entry point — or copy its body into the generated Xcode `App` struct.
6. Add a StoreKit Configuration File (`AtrestProducts.storekit`) for testing
   purchases in the simulator with these products:
   - `com.atrest.annual` — Auto-Renewable Subscription, $29.99/year
   - `com.atrest.lifetime` — Non-Consumable, $69.99
7. Configure signing with automatic signing (team will be set by the developer).
8. Add an `Info.plist` or use Xcode's generated one.
9. Remove `.iOSApplication(...)` and `.executableTarget(name: "App")` from
   `Package.swift` since the Xcode project now owns the app target.

**If you cannot create an Xcode project** (e.g., headless environment), proceed
with Option B.

### Option B — Document the limitation and clean up Package.swift

If the Xcode project cannot be created, make these changes:

**File:** `Package.swift`

**Find and remove this entire block from the `products` array:**

```swift
        .iOSApplication(
            name: "AtrestFastingApp",
            targets: ["App"],
            bundleIdentifier: "app.atrest.fasting",
            teamIdentifier: "TEAMID",
            displayVersion: "1.0",
            bundleVersion: "1",
            iconAssetName: nil,
            accentColorAssetName: nil,
            supportedDeviceFamilies: [.phone],
            supportedInterfaceOrientations: [.portrait]
        )
```

So the `products` array becomes:

```swift
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "UI", targets: ["UI"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Policy", targets: ["Policy"]),
    ],
```

Keep the `.executableTarget(name: "App", ...)` in the targets array — it still
compiles and can be used for `swift run` during development.

**Add a note to `README.md`** at the end of the "Release readiness notes" section:

```markdown
- **App Store submission** requires an Xcode project (`.xcodeproj`) wrapping this package. The SPM package alone cannot produce a signed `.ipa`. Create the project with: File → New → Project → iOS App, add this package as a local dependency, and configure signing + StoreKit configuration.
```

---

## Verification Checklist

After completing all tasks, verify each item:

| # | Check | Command / Action |
|---|-------|-----------------|
| 1 | Project compiles | `swift build` or `xcodebuild build -scheme AtrestFastingApp-Package -destination 'platform=iOS Simulator,name=iPhone 15' -sdk iphonesimulator` |
| 2 | Unit tests pass | `xcodebuild test -scheme AtrestFastingApp-Package -destination 'platform=iOS Simulator,name=iPhone 15' -sdk iphonesimulator -only-testing:UnitTests` |
| 3 | Policy tests pass | same command with `-only-testing:PolicyTests` |
| 4 | Snapshot tests pass (if baselines generated) | same command with `-only-testing:SnapshotTests` |
| 5 | SwiftLint clean | `swiftlint --config .swiftlint.yml` |
| 6 | No deprecated-onChange warnings | Search for `{ _ in` in `TimerScreen.swift` — should be zero matches |
| 7 | `reconcile()` uses pattern matching | Search for `if case .purchased = outcome` in `Entitlements.swift` — should match |
| 8 | URLs are HTTPS | `grep "http://" Sources/UI/Resources/Localizable.strings` — should return zero |
| 9 | README is consistent | Read README.md and confirm no mention of `isRecording = true` |
| 10 | Trial notice appears on Timer | Run app, complete 11 fasts, verify banner text on Timer screen |

---

## Summary of Changes

| Task | Severity | Files Modified | Lines Changed (approx) |
|------|----------|---------------|----------------------|
| TASK-1 | CRITICAL | `Sources/Data/Entitlements.swift` | 5 |
| TASK-2 | HIGH | `Tests/SnapshotTests/*.swift`, `__Snapshots__/*` | 2 + generated files |
| TASK-3 | LOW | `.swiftlint.yml` | full file |
| TASK-4 | LOW | `Sources/UI/TimerScreen.swift` | 2 |
| TASK-5 | MEDIUM | `Sources/UI/TimerViewModel.swift`, `Sources/UI/TimerScreen.swift`, `Sources/UI/RootView.swift` | ~15 |
| TASK-6 | LOW | `Sources/UI/Resources/Localizable.strings` | 2 |
| TASK-7 | LOW | `README.md` | 1 |
| TASK-8 | HIGH | `Package.swift`, `README.md` (or Xcode project creation) | varies |
| TASK-9 | MEDIUM | `Sources/UI/SettingsViewModel.swift` | 3 |
| TASK-10 | MEDIUM | `Sources/UI/RootView.swift` | 5 |
| TASK-11 | LOW | `Sources/App/AtrestApp.swift` | ~20 (deletion) |

---

## TASK-9 — Add security-scoped resource access to file import (MEDIUM — NEW-A)

**File:** `Sources/UI/SettingsViewModel.swift`

**Problem:** On real iOS devices, URLs returned by `.fileImporter()` are
*security-scoped resources*. You must call `url.startAccessingSecurityScopedResource()`
before reading and `url.stopAccessingSecurityScopedResource()` after. Without this,
`Data(contentsOf: url)` silently fails on real devices because the sandbox blocks
access. This works in the Simulator but **breaks in production**.

**Find this exact code** (the `importFile` method):

```swift
    public func importFile(at url: URL, strategy: SessionMergeStrategy = .mergeDedup) async throws {
        guard let sessionStore else { throw SettingsError.unavailable }
        let data = try Data(contentsOf: url)
        let validated = try importService.validate(data: data)
        let sessions = importService.apply(validated)
        let state = try await sessionStore.merge(imported: sessions, strategy: strategy)
        onStoreUpdate?(state)
        statusMessage = L10n.importSuccess
    }
```

**Replace with:**

```swift
    public func importFile(at url: URL, strategy: SessionMergeStrategy = .mergeDedup) async throws {
        guard let sessionStore else { throw SettingsError.unavailable }
        guard url.startAccessingSecurityScopedResource() else {
            throw SettingsError.unavailable
        }
        defer { url.stopAccessingSecurityScopedResource() }
        let data = try Data(contentsOf: url)
        let validated = try importService.validate(data: data)
        let sessions = importService.apply(validated)
        let state = try await sessionStore.merge(imported: sessions, strategy: strategy)
        onStoreUpdate?(state)
        statusMessage = L10n.importSuccess
    }
```

**What changed:** Added `startAccessingSecurityScopedResource()` guard before
reading, with a `defer` block to always release the resource. If the security scope
cannot be obtained, it throws `SettingsError.unavailable`.

**Why this matters:** Without this, every import on a real device silently fails.
Apple's documentation explicitly requires this for URLs from document pickers and
file importers.

---

## TASK-10 — Show trial notice only once, not on every foreground (MEDIUM — NEW-B)

**File:** `Sources/UI/RootView.swift`

**Problem:** `reconcileEntitlements()` runs on every foreground. Each time, if
`completedCount == 11`, it re-sets `timerViewModel.trialNotice` — even if the
user already dismissed it via tap. The contract says **"one non-intrusive notice
at completion"**, meaning it should appear once, not repeatedly.

### Step 10a — Add a flag to RootView

**Find this code at the top of `RootView`:**

```swift
    private let sessionStore: SessionStore?
    private let entitlementService: EntitlementServicing
    @Environment(\.scenePhase) private var scenePhase
```

**Replace with:**

```swift
    private let sessionStore: SessionStore?
    private let entitlementService: EntitlementServicing
    @State private var trialNoticeShown = false
    @Environment(\.scenePhase) private var scenePhase
```

### Step 10b — Guard the notice behind the flag

**Find this code inside `updateDerivedData`:**

```swift
        if TrialPolicy.isNoticeDue(completed: state.completedCount) && effectiveEntitlement != .premium {
            paywallViewModel.setStatusMessage(L10n.paywallTrialNotice)
            timerViewModel.trialNotice = L10n.paywallTrialNotice
        }
```

**Replace with:**

```swift
        if TrialPolicy.isNoticeDue(completed: state.completedCount) && effectiveEntitlement != .premium && !trialNoticeShown {
            paywallViewModel.setStatusMessage(L10n.paywallTrialNotice)
            timerViewModel.trialNotice = L10n.paywallTrialNotice
            trialNoticeShown = true
        }
```

**What changed:** Added `@State private var trialNoticeShown = false` and a
`!trialNoticeShown` guard. Once the notice is shown once per app session, it
won't re-appear on subsequent foreground cycles. The flag resets on app restart,
which is acceptable — the contract says "one non-intrusive notice at completion,"
and showing it once per fresh launch at fast 11 is reasonable.

---

## TASK-11 — Remove dead `FallbackPurchaseClient` and iOS 16 availability check (LOW — NEW-C)

**File:** `Sources/App/AtrestApp.swift`

**Problem:** The deployment target is iOS 17. The `if #available(iOS 16.0, *)` check
always evaluates to `true`, meaning `FallbackPurchaseClient` is dead code that can
never execute. This is misleading — a reviewer might think iOS 15 support exists.

**Find this code in the `init()` method:**

```swift
    init() {
        if #available(iOS 16.0, *) {
            self.purchaseClient = StoreKitPurchaseClient()
        } else {
            self.purchaseClient = FallbackPurchaseClient()
        }
        self.entitlementService = EntitlementService(
```

**Replace with:**

```swift
    init() {
        self.purchaseClient = StoreKitPurchaseClient()
        self.entitlementService = EntitlementService(
```

**Then find and delete the entire `FallbackPurchaseClient` struct** at the bottom of
the file:

```swift
private struct FallbackPurchaseClient: PurchaseClient {
    func products(ids: [String]) async throws -> [StoreProductInfo] {
        ids.compactMap { id in
            guard let product = PurchaseProduct(rawValue: id) else { return nil }
            switch product {
            case .annual:
                return StoreProductInfo(id: id, displayName: "Annual", displayPrice: "—")
            case .lifetime:
                return StoreProductInfo(id: id, displayName: "Lifetime", displayPrice: "—")
            }
        }
    }

    func purchase(productID: String) async throws -> PurchaseOutcome { .notFound }
    func restoreEntitlements(productIDs: [String]) async throws -> PurchaseOutcome { .notFound }
    func currentEntitlement(productIDs: [String]) async throws -> PurchaseOutcome { .notFound }
}
```

**Replace with nothing** (delete the entire block).

---

## Updated Verification Checklist (including TASK-9 through TASK-11)

| # | Check | Command / Action |
|---|-------|-----------------|
| 11 | Security-scoped resource used | Search for `startAccessingSecurityScopedResource` in `SettingsViewModel.swift` — should match |
| 12 | Trial notice shows once | Search for `trialNoticeShown` in `RootView.swift` — should match |
| 13 | No `FallbackPurchaseClient` | Search for `FallbackPurchaseClient` in all files — should return zero matches |
| 14 | No `#available(iOS 16` | Search for `#available` in `AtrestApp.swift` — should return zero matches |
| 15 | Import works on device | Run on a physical device, export data, then import the file — confirm success message appears |
