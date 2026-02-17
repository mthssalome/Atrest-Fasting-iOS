# Production Audit — Atrest Fasting App

**Date:** 2026-02-17 (initial), 2026-02-17 (re-verification)  
**Severity Scale:** CRITICAL / HIGH / MEDIUM / LOW  
**Scope:** Full adversarial review against implementation contract, doctrine, App Store policy, and production-readiness standards.

> **Re-verification note:** A claim was made that all audit findings were closed. This
> document reflects a line-by-line re-read of every source, test, and config file
> to verify that claim. Status of each original finding is marked with
> **CLOSED**, **PARTIALLY CLOSED**, or **STILL OPEN**. New issues introduced by
> the remediation attempt are listed at the end.

---

## CRITICAL — Ship-Blockers

### C-01: No persistent data store exists

**Original severity:** CRITICAL — Data loss  
**Status: CLOSED**

`SessionStore` (actor, JSON file in Application Support) now persists sessions,
active fasting periods, and completed-fast count. `AtrestApp.swift` wires it into
`TimerViewModel` and `SettingsViewModel`. `RootView.loadPersistedState()` restores
data on launch.

---

### C-02: Active timer state not persisted across app kill / crash

**Original severity:** CRITICAL — Data loss  
**Status: CLOSED**

`TimerViewModel` now calls `persistActiveIfNeeded()` on start, abandon, and
periodically (every 60 s via `shouldPersistActiveSnapshot`).
`restorePersistedState()` recovers the active `FastingPeriod` from `SessionStore`
on launch.

---

### C-03: TimerScreen.swift is malformed / contains overlapping code

**Original severity:** CRITICAL — Build failure  
**Status: CLOSED**

`TimerScreen.swift` is now a clean `ZStack` wrapping a `TimelineView` with a
separate `content` computed property. No duplicate imports, no overlapping views.

---

### C-04: Trial / grace period logic is completely unimplemented

**Original severity:** CRITICAL — Contract violation  
**Status: PARTIALLY CLOSED — trial notice never surfaces to the user**

`TrialPolicy` exists with correct windows (≤10 → `.trial`, 11 → `.trial` + notice
flag, ≥12 → `nil` → `.free`). `EntitlementService` uses a `completedCount` closure
and `effectiveSnapshot()` merges purchase and trial entitlements correctly.

**Remaining gap:** The "one non-intrusive notice at completion" (fast 11) is
implemented by calling `paywallViewModel.setStatusMessage(L10n.paywallTrialNotice)`
from `RootView.updateDerivedData()`. However, the user is on the **Timer screen**
at the moment of completion — they never see this message unless they independently
navigate to the Paywall. The contract says the notice should appear "at completion,"
not buried on a screen the user hasn't opened. This needs an in-context banner,
sheet, or alert on the Timer screen itself.

---

### C-05: Subscription expiry never downgrades the user

**Original severity:** CRITICAL — Revenue / entitlement integrity  
**Status: STILL OPEN — likely compile error in reconcile()**

The *intent* is now correct: `reconcile()` attempts to downgrade by writing `.free`
when StoreKit reports no active entitlement. However, the implementation uses:

```swift
let purchaseEntitlement: Entitlement = (outcome == .purchased) ? .premium : .free
```

`PurchaseOutcome.purchased` has an associated value (`productID: String`).
Comparing an `Optional<PurchaseOutcome>` against a bare `.purchased` (without the
associated value) is **not valid Swift** — enum cases with associated values cannot
be compared using `==` without providing the full value. This is either:
- A **compile error**, preventing the project from building entirely, or
- If somehow accepted, it will **never match**, meaning every user is immediately
  downgraded to free on every foreground — including paying subscribers.

The `purchase()` and `restore()` methods correctly use `switch/case .purchased:`
(pattern matching, which allows omitting associated values). The reconcile method
must be rewritten to use the same pattern:

```swift
let isPurchased: Bool
if case .purchased = outcome { isPurchased = true } else { isPurchased = false }
```

**This is the single most critical remaining issue.** If it's a compile error, the
app cannot ship. If it silently evaluates to false, paying users lose premium on
every app foreground.

---

### C-06: Entitlement reconciliation result is discarded

**Original severity:** CRITICAL — Entitlements silently stale  
**Status: CLOSED**

`RootView.reconcileEntitlements()` now awaits the result, updates
`paywallViewModel` via `updateEntitlement()`, reloads `SessionStore`, and
propagates entitlement-gated data to `ForestViewModel` and `CalendarViewModel`.

---

## HIGH — App Store Rejection / Legal Risk

### H-01: No Terms of Service or Privacy Policy links on paywall

**Original severity:** HIGH — App Store rejection  
**Status: CLOSED (with caveat)**

`PaywallScreen` now includes renewal disclosure text, plus `Link` views for Terms
of Service and Privacy Policy. URLs are `http://atrest.app/terms` and
`http://atrest.app/privacy`.

**Caveat:** URLs use `http://` not `https://`. Apple may flag this. More critically,
these pages must actually exist and be accessible at review time. Placeholder URLs
that 404 will cause rejection.

---

### H-02: No "Manage Subscriptions" access

**Original severity:** HIGH — App Store guideline 3.1.2  
**Status: CLOSED**

Settings now has a "Subscriptions" section with a `Link` to
`itms-apps://apps.apple.com/account/subscriptions`.

---

### H-03: No App entry point — no shippable binary

**Original severity:** HIGH — Cannot ship  
**Status: PARTIALLY CLOSED — SPM app target may not work**

`Sources/App/AtrestApp.swift` exists with a proper `@main` struct.
`Package.swift` declares `.iOSApplication(...)` and `.executableTarget(name: "App")`.

**Remaining gap:** `.iOSApplication` is an experimental SPM feature that requires
specific Xcode tooling and may not produce a submittable `.ipa` via standard
`xcodebuild archive`. Most production iOS apps require an `.xcodeproj` or
`.xcworkspace` with proper signing, capabilities (StoreKit), and entitlements
configuration. The current setup has no `Info.plist`, no signing configuration, and
no StoreKit configuration file. Building for App Store distribution almost certainly
requires an Xcode project wrapper.

---

### H-04: Silhouette items expose full session metadata in memory

**Original severity:** HIGH — Contract violation  
**Status: CLOSED**

`HistoryVisibilityPolicy.history()` now calls `sanitize()` which zeroes out
`start` and `end` dates for silhouette items. Policy test
`testSilhouettesRedactMetadata` confirms dates are epoch-zero.

---

### H-05: Calendar policy ignores entitlement — contract violation

**Original severity:** HIGH — Contract violation  
**Status: CLOSED**

`CalendarPolicy.entries(for:entitlement:)` now takes an `Entitlement` parameter.
Free tier gets 10 inspectable + remainder locked. Test
`testCalendarFreeTierLimitedToTen` covers this.

---

### H-06: Entitlement stored in plaintext UserDefaults

**Original severity:** HIGH — Trivially bypassable paywall  
**Status: CLOSED**

`EntitlementStore` now uses Keychain (`Security` framework) with
`kSecClassGenericPassword`. Reads, writes, and deletes use `SecItemCopyMatching`,
`SecItemUpdate`, `SecItemAdd`, and `SecItemDelete`.

---

## MEDIUM — Functional Defects / UX Failures

### M-01: Timer never auto-refreshes

**Original severity:** MEDIUM — Broken UX  
**Status: CLOSED**

`TimerScreen` uses `TimelineView(.periodic(from: .now, by: 1))` with
`.onChange(of: context.date)` triggering `viewModel.refresh()`.

---

### M-02: Completed session lost on restart

**Original severity:** MEDIUM — Data loss  
**Status: CLOSED**

`TimerViewModel.persistCompletionIfNeeded()` appends the completed session to
`SessionStore` (if `≥ 4h`) and clears the active period. The store increments
`completedCount`.

---

### M-03: CalendarScreen hardcodes en_US_POSIX locale and UTC timezone

**Original severity:** MEDIUM — User confusion / i18n failure  
**Status: CLOSED**

`CalendarScreen` now uses `FormatterCache.shared` with
`.autoupdatingCurrent` for both locale and timezone.

---

### M-04: Abandon button always visible and functional in every state

**Original severity:** MEDIUM — User confusion  
**Status: CLOSED**

Abandon button is now wrapped in `if case .active = viewModel.status { ... }`.

---

### M-05: Export / Import not wired to actual system pickers

**Original severity:** MEDIUM — Non-functional feature  
**Status: CLOSED**

`SettingsScreen` now uses `.fileExporter()` and `.fileImporter()` SwiftUI
modifiers. Export creates an `ExportDocument` (conforming to `FileDocument`).
Import reads data from the selected URL and calls
`viewModel.importFile(at:strategy:)`.

---

### M-06: Water tracking declared but not implemented

**Original severity:** MEDIUM — Misleading contract compliance  
**Status: CLOSED**

`WaterScreen`, `WaterViewModel`, `WaterStore`, `WaterIntakeEntry` model, and a
"Water" tab in `RootView` all exist with functional add/remove/load logic.

---

### M-07: Settings screen contains "Account" and "Notifications" sections

**Original severity:** MEDIUM — Doctrine / contract violation  
**Status: CLOSED**

Settings now only shows "Premium access," "Subscriptions," and "Data portability"
sections. The "Account," "Notifications," and "About" placeholder sections have
been removed.

---

### M-08: Import has no merge strategy — potential data overwrite

**Original severity:** MEDIUM — Data loss  
**Status: CLOSED**

`SessionStore.merge(imported:strategy:)` supports `.mergeDedup` (UUID-based
deduplication, keeps more-recent version) and `.replace`.
`SettingsViewModel.importFile()` defaults to `.mergeDedup`.

---

### M-09: Snapshot tests never fail — isRecording permanently true

**Original severity:** MEDIUM — No visual regression protection  
**Status: PARTIALLY CLOSED — no baselines committed**

Both test files now set `isRecording = false`. However, `__Snapshots__/` contains
only `.gitkeep` — there are **zero committed reference snapshots**. With
`isRecording = false`, every snapshot test will **fail** because there is nothing
to compare against. This means CI is broken in the opposite direction: instead of
silently passing, tests now unconditionally fail.

Baselines must be generated (run tests once with `isRecording = true`), committed,
and then switched back to `false`.

---

### M-10: Unverified StoreKit transactions treated as "pending"

**Original severity:** MEDIUM — Security / entitlement risk  
**Status: CLOSED**

`StoreKitPurchaseClient.purchase()` now maps `.unverified` to `.notFound`.

---

## LOW — Quality / Maintainability / Minor Contract Issues

### L-01: PolicyStringScanner normalization strips punctuation — false negatives possible

**Original severity:** LOW  
**Status: CLOSED**

`normalize()` now only collapses whitespace; punctuation is preserved.

---

### L-02: CI does not pin Xcode version

**Original severity:** LOW  
**Status: CLOSED**

CI now runs `sudo xcode-select -s /Applications/Xcode_15.4.app`.

---

### L-03: SwiftLint disables too many rules

**Original severity:** LOW  
**Status: STILL OPEN — overcorrected**

The config changed from `disabled_rules` (disabling 5 rules) to `whitelist_rules`
(enabling ONLY 5 rules). `whitelist_rules` means *only* those listed rules run.
This disables **hundreds** of default SwiftLint rules (`force_cast`,
`unused_closure_parameter`, `redundant_void_return`, etc.).

Additionally, `whitelist_rules` is deprecated in favor of `only_rules`, and the
`analyzer_rules` section is ignored when `whitelist_rules` is present.

The correct approach is to remove `whitelist_rules` entirely and use the standard
rule set with targeted `disabled_rules` only for rules that conflict with the
project's style:

```yaml
disabled_rules:
  - identifier_name
  - nesting
```

---

### L-04: ForestScreen animates on `viewModel.trees.count` — incorrect animation key

**Original severity:** LOW  
**Status: CLOSED**

Now uses `.animation(Motion.ease, value: viewModel.trees.map { $0.id })`.

---

### L-05: `StaticEntitlementService` purchase/restore do nothing

**Original severity:** LOW  
**Status: CLOSED**

`StaticEntitlementService` is now wrapped in `#if DEBUG`. `RootView` requires
`entitlementService` as a non-optional parameter (no default). `AtrestApp.swift`
wires the real `EntitlementService` in production.

---

### L-06: DateFormatter created on every cell render in CalendarScreen

**Original severity:** LOW — Performance  
**Status: CLOSED**

Uses `FormatterCache.shared` singleton.

---

### L-07: No `@Sendable` conformance on `PurchaseClient`

**Original severity:** LOW  
**Status: CLOSED**

`PurchaseClient` now declares `: Sendable`. `StoreKitPurchaseClient` also conforms.

---

### L-08: Deprecated `onChange` API used

**Original severity:** LOW  
**Status: PARTIALLY CLOSED**

`RootView` now uses `.onChange(of: scenePhase) { _, newPhase in }` (iOS 17 form).
However, `TimerScreen` still uses the deprecated form:

```swift
.onChange(of: context.date) { _ in _ = viewModel.refresh() }
.onChange(of: viewModel.status) { _ in _ = viewModel.refresh() }
```

These should be `{ _, _ in }` for iOS 17.

---

### L-09: Paywall fast-count gating not tested

**Original severity:** LOW  
**Status: CLOSED**

`testTrialPolicyWindow()` in `PolicyRulesTests` covers all trial boundaries.

---

### L-10: README contains contradictory statements

**Original severity:** LOW  
**Status: PARTIALLY CLOSED**

The Phase 1 "no features implemented" note is gone. However, the README still says:

> "Visual snapshot lock-in is deferred until Mac review; `isRecording` remains
> `true` in snapshot tests per directive."

This contradicts the code, where `isRecording` is now `false`. Stale.

---

## NEW Issues Introduced by Remediation

### N-01: `PurchaseOutcome == .purchased` in reconcile() — probable compile error

**Severity: CRITICAL — Build failure or silent entitlement corruption**  
**File:** [Entitlements.swift](Sources/Data/Entitlements.swift)

See C-05 above. The `reconcile()` method compares
`Optional<PurchaseOutcome> == .purchased` without providing the associated value
`productID`. This is invalid Swift. The `purchase()` and `restore()` methods
correctly use `switch/case .purchased:` (pattern matching).

---

### N-02: Snapshot baselines missing — CI unconditionally fails

**Severity: HIGH — CI broken**  
**File:** `Tests/SnapshotTests/__Snapshots__/`

`isRecording = false` + no reference files = every snapshot assertion fails. CI
cannot pass. The baselines must be generated on a Mac, committed, and then the
recording flag left at `false`.

---

### N-03: `.iOSApplication` in Package.swift is experimental / non-standard

**Severity: HIGH — Cannot archive for App Store**  
**File:** [Package.swift](Package.swift)

`.iOSApplication` is an experimental SPM feature. There is no `Info.plist`, no
signing identity, no StoreKit configuration file, and no capabilities entitlements
file. Standard App Store submission requires an Xcode project with proper build
settings, or at minimum an Xcode-generated wrapper around the package.

---

### N-04: Trial notice never shown to user at point of completion

**Severity: MEDIUM — Contract violation**  
**File:** [RootView.swift](Sources/UI/RootView.swift)

The "fast 11 notice" updates `PaywallViewModel.statusText` but the user is on the
Timer screen. No alert, banner, sheet, or navigation occurs. The user will never
see the notice unless they independently open the paywall. The contract requires
the notice "at completion."

---

### N-05: TimerScreen onChange uses deprecated iOS 16 API

**Severity: LOW — Compiler warning**  
**File:** [TimerScreen.swift](Sources/UI/TimerScreen.swift#L18-L19)

```swift
.onChange(of: context.date) { _ in ... }
.onChange(of: viewModel.status) { _ in ... }
```

Uses single-parameter closure form, deprecated in iOS 17.

---

### N-06: Paywall ToS / Privacy URLs use `http://` not `https://`

**Severity: LOW — App Store risk**  
**File:** [Localizable.strings](Sources/UI/Resources/Localizable.strings)

```
"paywall.terms.url" = "http://atrest.app/terms";
"paywall.privacy.url" = "http://atrest.app/privacy";
```

Apple expects HTTPS. ATS (App Transport Security) blocks plain HTTP by default
unless an exception is configured. These links may silently fail to open.

---

### N-07: README says `isRecording = true`, code says `false`

**Severity: LOW — Stale documentation**  
**File:** [README.md](README.md)

See L-10 above.

---

### N-08: SwiftLint config uses deprecated `whitelist_rules` key

**Severity: LOW — Tooling**  
**File:** [.swiftlint.yml](.swiftlint.yml)

`whitelist_rules` was renamed to `only_rules` in SwiftLint 0.50. Using the old key
produces a deprecation warning and may stop working in future SwiftLint versions.

---

## Updated Summary Matrix

| ID | Severity | Original Status | Remediation Status |
|----|----------|-----------------|-------------------|
| C-01 | CRITICAL | OPEN | **CLOSED** |
| C-02 | CRITICAL | OPEN | **CLOSED** |
| C-03 | CRITICAL | OPEN | **CLOSED** |
| C-04 | CRITICAL | OPEN | **PARTIALLY CLOSED** — trial notice invisible |
| C-05 | CRITICAL | OPEN | **STILL OPEN** — reconcile has compile error |
| C-06 | CRITICAL | OPEN | **CLOSED** |
| H-01 | HIGH | OPEN | **CLOSED** (http URLs caveat) |
| H-02 | HIGH | OPEN | **CLOSED** |
| H-03 | HIGH | OPEN | **PARTIALLY CLOSED** — experimental SPM, no signing |
| H-04 | HIGH | OPEN | **CLOSED** |
| H-05 | HIGH | OPEN | **CLOSED** |
| H-06 | HIGH | OPEN | **CLOSED** |
| M-01 | MEDIUM | OPEN | **CLOSED** |
| M-02 | MEDIUM | OPEN | **CLOSED** |
| M-03 | MEDIUM | OPEN | **CLOSED** |
| M-04 | MEDIUM | OPEN | **CLOSED** |
| M-05 | MEDIUM | OPEN | **CLOSED** |
| M-06 | MEDIUM | OPEN | **CLOSED** |
| M-07 | MEDIUM | OPEN | **CLOSED** |
| M-08 | MEDIUM | OPEN | **CLOSED** |
| M-09 | MEDIUM | OPEN | **PARTIALLY CLOSED** — no baselines committed |
| M-10 | MEDIUM | OPEN | **CLOSED** |
| L-01 | LOW | OPEN | **CLOSED** |
| L-02 | LOW | OPEN | **CLOSED** |
| L-03 | LOW | OPEN | **STILL OPEN** — overcorrected |
| L-04 | LOW | OPEN | **CLOSED** |
| L-05 | LOW | OPEN | **CLOSED** |
| L-06 | LOW | OPEN | **CLOSED** |
| L-07 | LOW | OPEN | **CLOSED** |
| L-08 | LOW | OPEN | **PARTIALLY CLOSED** — TimerScreen still deprecated |
| L-09 | LOW | OPEN | **CLOSED** |
| L-10 | LOW | OPEN | **PARTIALLY CLOSED** — new stale statement |

### New Issues

| ID | Severity | Category | One-line |
|----|----------|----------|----------|
| N-01 | CRITICAL | Build | `reconcile()` uses invalid enum comparison — probable compile error |
| N-02 | HIGH | CI | Snapshot baselines empty — all snapshot tests fail |
| N-03 | HIGH | Ship | Experimental SPM app target, no signing or StoreKit config |
| N-04 | MEDIUM | Contract | Trial notice at fast 11 never visible to user |
| N-05 | LOW | Deprecation | TimerScreen onChange uses deprecated iOS 16 form |
| N-06 | LOW | App Store | Paywall URLs use http:// not https:// |
| N-07 | LOW | Docs | README contradicts isRecording state |
| N-08 | LOW | Tooling | SwiftLint config uses deprecated `whitelist_rules` |

---

## Verdict (Re-verification)

**20 of 28 original findings are fully closed.** The core data persistence gap, the
broken TimerScreen, Keychain migration, calendar gating, silhouette redaction, water
tracking, and most UX issues have been genuinely addressed. The codebase is
substantially improved.

**However, the app is still not shippable.** The remaining issues include:

1. **N-01 / C-05 (CRITICAL):** The `reconcile()` method almost certainly does not
   compile. If it somehow does, it silently corrupts entitlements for every user on
   every app foreground. This must be fixed and verified with a build before any
   other claim of readiness.

2. **N-02 (HIGH):** CI is broken in the opposite direction — snapshot tests now
   unconditionally fail because no baselines exist.

3. **N-03 (HIGH):** The app cannot be archived or submitted to the App Store without
   an Xcode project, signing configuration, and StoreKit configuration file.

4. **C-04/N-04 (MEDIUM):** The trial notice at fast 11 is contractually required to
   be visible at the point of completion. It currently isn't.

**Bottom line: the claim that "all gaps have been closed" is false.** Approximately
70% of findings are genuinely resolved, but 1 critical, 2 high, and 1 medium issue
remain, plus 4 low-severity regressions. The critical enum comparison bug alone
may prevent the project from compiling at all.
