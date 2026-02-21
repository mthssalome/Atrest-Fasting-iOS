# Implementation Supplement — Integration Seams

Read `spec/implementation-handover.md` first. This document resolves
the ambiguities that would otherwise force a coding instance to guess.

---

## 1. Entitlement Resolution Flow

The app already has a complete entitlement stack. Here's the flow:

```
StoreKit 2 receipt
        │
        ▼
EntitlementService.reconcile()        ← called in RootView.onAppear + scenePhase .active
  ├─ purchaseClient.currentEntitlement()  → .purchased or .notFound
  ├─ if purchased → store.save(.premium) → return .premium
  └─ if not purchased:
       └─ TrialPolicy.entitlement(forCompleted: count)
            ├─ count ≤ 10  → return .trial
            └─ count > 10  → return nil → falls through to .free
                                          │
                                          ▼
                              EntitlementSnapshot { .free, source, date }
```

### Current files and their roles

| File | Role | Changes needed |
|---|---|---|
| `Data/Entitlements.swift` | `EntitlementService` actor (composes StoreKit + trial), `EntitlementStore` (Keychain), `PurchaseClient` protocol, `StoreKitPurchaseClient` (real StoreKit 2) | **None.** This file works correctly. |
| `UI/EntitlementAdapters.swift` | `StaticEntitlementService` — `#if DEBUG` mock for previews/tests | **None.** |
| `Policy/PolicyRules.swift` | `TrialPolicy.entitlement(forCompleted:)` — trial window logic | **Update** per handover Phase F1 |
| `Domain/Models.swift` | `Entitlement` enum (`.free`, `.premium`, `.trial`) | **None.** Three cases are correct. |

### What to change in TrialPolicy

```swift
public enum TrialPolicy {
    /// First 10 completed fasts → .trial (full experience).
    /// After 10 → nil (falls through to .free or .premium in EntitlementService).
    public static func entitlement(forCompleted count: Int) -> Entitlement? {
        count <= 10 ? .trial : nil
    }

    /// The transition moment fires exactly once: when the 10th fast completes.
    /// After it has been dismissed, `transitionDismissed` is persisted via UserDefaults.
    public static func shouldShowTransitionMoment(completedCount: Int) -> Bool {
        completedCount == 10 && !UserDefaults.standard.bool(forKey: "atrest.transition.dismissed")
    }

    public static func markTransitionDismissed() {
        UserDefaults.standard.set(true, forKey: "atrest.transition.dismissed")
    }
}
```

Remove `isNoticeDue` entirely.

### How entitlement reaches the UI

`EntitlementService` is injected into `RootView` already. `RootView.reconcileEntitlements()`
calls `entitlementService.reconcile()` and pushes the resulting `EntitlementSnapshot` into
`PaywallViewModel.updateEntitlement()` — this already works.

The **new navigation needs the entitlement** to gate forest access and show/hide the
"Go premium" link. The simplest approach:

```swift
// In RootView — new @State property:
@State private var currentEntitlement: Entitlement = .free

// Set it alongside the existing paywallViewModel update:
private func reconcileEntitlements() {
    Task {
        let snapshot = await entitlementService.reconcile()
        await MainActor.run {
            paywallViewModel.updateEntitlement(snapshot)
            currentEntitlement = snapshot.entitlement     // ← add this
        }
        // ...existing sessionStore logic unchanged...
    }
}
```

Then pass `currentEntitlement` down to navigation views as a binding or plain value.

### Where entitlement is consumed (gate map)

| Consumer | What it gates | How to access |
|---|---|---|
| Navigation (forest icon) | Hide when `.free` | `currentEntitlement` in RootView |
| Navigation (transition moment) | Show when `TrialPolicy.shouldShowTransitionMoment` | `completedCount` from `SessionStoreState` + the policy check |
| ForestScreen | Not accessible when `.free` | Gated at navigation level — view never instantiated for `.free` |
| CalendarScreen | Shows 10 days when `.free`, all when `.trial`/`.premium` | Already handled by `CalendarPolicy.entries()` — no change |
| SettingsScreen ("Go premium") | Show when `.free` only | Pass `currentEntitlement` |
| PaywallScreen | Reachable only from settings (`.free`) or transition moment | Already has `PaywallViewModel.entitlement` |
| TimerScreen (tree) | Show tree when `.trial`/`.premium`, no tree when `.free` | Pass `currentEntitlement` |

---

## 2. Navigation State Machine

### View Hierarchy (exact SwiftUI structure)

```swift
public struct RootView: View {
    // ...existing @StateObject VMs, entitlementService...
    @State private var currentEntitlement: Entitlement = .free
    @State private var destination: AppDestination = .timer
    @State private var showCalendarSheet = false
    @State private var showSettingsSheet = false
    @State private var showPaywallSheet = false
    @State private var showTransitionMoment = false

    public var body: some View {
        ZStack {
            // Layer 1: Full-screen destination (timer or forest)
            switch destination {
            case .timer:
                timerContent
                    .transition(.opacity)
            case .forest:
                ForestScreen(viewModel: forestViewModel)
                    .transition(.opacity)
            }

            // Layer 2: Transition moment overlay (one-time, above everything)
            if showTransitionMoment {
                TransitionMomentView(
                    onContinue: {
                        showTransitionMoment = false
                        showPaywallSheet = true
                    },
                    onDismiss: {
                        TrialPolicy.markTransitionDismissed()
                        showTransitionMoment = false
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(Motion.slow, value: destination)
        .sheet(isPresented: $showCalendarSheet) {
            CalendarScreen(viewModel: calendarViewModel)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsScreen(
                viewModel: settingsViewModel,
                paywallViewModel: paywallViewModel,
                entitlement: currentEntitlement,
                onShowPaywall: {
                    showSettingsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPaywallSheet = true
                    }
                }
            )
            .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallScreen(viewModel: paywallViewModel)
                .presentationBackground(.ultraThinMaterial)
        }
        .task { await loadPersistedState() }
        .onAppear { reconcileEntitlements() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { reconcileEntitlements() }
        }
    }

    @ViewBuilder
    private var timerContent: some View {
        ZStack {
            TimerScreen(
                viewModel: timerViewModel,
                waterViewModel: waterViewModel,
                entitlement: currentEntitlement
            )

            // During active fast: escape hatch glyph top-left
            if case .active = timerViewModel.status {
                EscapeHatchOverlay(
                    entitlement: currentEntitlement,
                    onForest: { destination = .forest },
                    onCalendar: { showCalendarSheet = true },
                    onSettings: { showSettingsSheet = true }
                )
            }

            // During idle: floating nav icons at bottom
            if case .idle = timerViewModel.status {
                FloatingNavIcons(
                    entitlement: currentEntitlement,
                    onForest: { destination = .forest },
                    onCalendar: { showCalendarSheet = true },
                    onSettings: { showSettingsSheet = true }
                )
            }
            // Also show floating icons for completed/abandoned states:
            if case .completed = timerViewModel.status {
                FloatingNavIcons(
                    entitlement: currentEntitlement,
                    onForest: { destination = .forest },
                    onCalendar: { showCalendarSheet = true },
                    onSettings: { showSettingsSheet = true }
                )
            }
            if case .abandoned = timerViewModel.status {
                FloatingNavIcons(
                    entitlement: currentEntitlement,
                    onForest: { destination = .forest },
                    onCalendar: { showCalendarSheet = true },
                    onSettings: { showSettingsSheet = true }
                )
            }
        }
    }
}

enum AppDestination: Equatable {
    case timer
    case forest
}
```

### Key Navigation Rules

1. **Forest is fullscreen, not a sheet.** It replaces the timer via `.transition(.opacity)` crossfade. ForestScreen includes its own back-to-timer tap target (a small Atrest glyph or "back" gesture).

2. **Calendar and Settings are sheets** with `.ultraThinMaterial` background — frosted glass over the current screen.

3. **Paywall is a sheet** — reached from Settings ("Go premium" link) or from the transition moment's "Continue" button. Settings sheet dismisses before paywall appears (0.3s delay to avoid sheet collision).

4. **The escape hatch** is NOT a button that navigates directly. It's a tap target (top-left during active fast) that expands a frosted overlay showing 2-3 icons. The user taps an icon to go somewhere. Tapping outside the overlay dismisses it. Implementation:

```swift
struct EscapeHatchOverlay: View {
    let entitlement: Entitlement
    let onForest: () -> Void
    let onCalendar: () -> Void
    let onSettings: () -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack {
            HStack {
                // The glyph button — top left
                Button { isExpanded.toggle() } label: {
                    Image(systemName: "leaf.circle")  // TODO: Replace with custom Atrest glyph SVG
                        .font(.title2)
                        .foregroundStyle(Palette.muted)
                        .opacity(0.30)
                }
                .padding(.leading, Spacing.lg)
                .padding(.top, Spacing.lg)
                Spacer()
            }
            Spacer()
        }
        .overlay {
            if isExpanded {
                // Frosted overlay with icons
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { isExpanded = false }

                    VStack(spacing: Spacing.xl) {
                        if entitlement != .free {
                            Button { isExpanded = false; onForest() } label: {
                                Image(systemName: "leaf")  // TODO: custom SVG
                                    .font(.title)
                                    .foregroundStyle(Palette.highlight)
                            }
                        }
                        Button { isExpanded = false; onCalendar() } label: {
                            Image(systemName: "circle.grid.3x3")  // TODO: custom SVG
                                .font(.title)
                                .foregroundStyle(Palette.highlight)
                        }
                        Button { isExpanded = false; onSettings() } label: {
                            Image(systemName: "gearshape")  // TODO: custom SVG
                                .font(.title)
                                .foregroundStyle(Palette.highlight)
                        }
                    }
                    .padding(Spacing.xl)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radii.soft))
                }
                .transition(.opacity)
            }
        }
        .animation(Motion.ease, value: isExpanded)
    }
}
```

5. **FloatingNavIcons** — bottom of screen during idle/completed/abandoned:

```swift
struct FloatingNavIcons: View {
    let entitlement: Entitlement
    let onForest: () -> Void
    let onCalendar: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: Spacing.xxl) {
                if entitlement != .free {
                    Button(action: onForest) {
                        Image(systemName: "leaf")  // TODO: custom SVG
                            .font(.title3)
                            .foregroundStyle(Palette.muted)
                    }
                }
                Button(action: onCalendar) {
                    Image(systemName: "circle.grid.3x3")  // TODO: custom SVG
                        .font(.title3)
                        .foregroundStyle(Palette.muted)
                }
                Button(action: onSettings) {
                    Image(systemName: "gearshape")  // TODO: custom SVG
                        .font(.title3)
                        .foregroundStyle(Palette.muted)
                }
            }
            .opacity(0.40)
            .padding(.bottom, Spacing.xl)
        }
    }
}
```

6. **Returning from forest:** ForestScreen needs a back mechanism. Two options (implement both):
   - Swipe-right gesture → `destination = .timer`
   - Small Atrest glyph in top-left corner → tap returns to timer

   ForestScreen needs a callback `onBack: () -> Void` passed from RootView.

### Transition Moment Trigger

In `updateDerivedData`:

```swift
private func updateDerivedData(from state: SessionStoreState, entitlement: Entitlement? = nil) {
    let effectiveEntitlement = entitlement ?? paywallViewModel.entitlement.entitlement

    // Existing: update forest and calendar
    // ...

    // NEW: Check transition moment
    if TrialPolicy.shouldShowTransitionMoment(completedCount: state.completedCount)
        && effectiveEntitlement != .premium {
        showTransitionMoment = true
    }

    // REMOVED: old trialNotice/isNoticeDue logic
}
```

---

## 3. Timer Screen Layout Hierarchy

```swift
struct TimerScreen: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var waterViewModel: WaterViewModel
    let entitlement: Entitlement

    var body: some View {
        ZStack {
            // Layer 0: Atmospheric background (always)
            DuskBackground()
                .ignoresSafeArea()

            // Layer 1: Tree materialization (premium/trial during active fast only)
            if case .active = viewModel.status,
               entitlement != .free {
                TreeMaterializationView(
                    variantIndex: viewModel.activeTreeVariantIndex,
                    toneIndex: viewModel.activeTreeToneIndex,
                    progress: viewModel.materializationProgress,
                    showStar: viewModel.isJustCompleted
                )
                .ignoresSafeArea()
            }

            // Layer 2: Content
            VStack(spacing: 0) {
                Spacer()

                // Elapsed time — large centered
                if case .active = viewModel.status {
                    Text(viewModel.formattedElapsed)
                        .font(Typography.elapsed)
                        .foregroundStyle(Palette.highlight)
                        .monospacedDigit()
                }

                // Milestone — companion text
                if let milestone = viewModel.milestone {
                    Text(viewModel.milestoneLabel)
                        .font(Typography.body)
                        .foregroundStyle(Palette.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.sm)
                }

                // Idle state prompt
                if case .idle = viewModel.status {
                    Text(L10n.timerIdlePrompt)
                        .font(Typography.body)
                        .foregroundStyle(Palette.accent)
                }

                // Completed state label
                if case .completed = viewModel.status {
                    Text(L10n.timerCompletedLabel)
                        .font(Typography.heading)
                        .foregroundStyle(Palette.highlight)
                }

                Spacer()

                // Water inline (active fast only)
                if case .active = viewModel.status {
                    WaterInlineView(viewModel: waterViewModel)
                        .padding(.bottom, Spacing.md)
                }

                // Primary action button
                Button(action: { viewModel.primaryAction() }) {
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

                // Abandon button (active only)
                if case .active = viewModel.status {
                    Button(action: { viewModel.abandon() }) {
                        Text(L10n.timerActionAbandon)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.muted)
                    }
                    .padding(.top, Spacing.sm)
                }

                Spacer().frame(height: Spacing.xxl)
            }
        }
    }
}
```

### What `formattedElapsed` looks like

```swift
// In TimerViewModel — new computed property
public var formattedElapsed: String {
    let totalSeconds = Int(durationHours * 3600)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    return "\(hours)h \(minutes)m"
}
```

---

## 4. `targetDurationHours` Data Flow

### Where it's written

In `SettingsScreen` → picker → writes to `UserDefaults`:

```swift
// In SettingsViewModel
@AppStorage("atrest.fasting.targetHours") public var targetHours: Double = 16.0
```

### Where it's stamped on a session

In `FastingSessionMachine.complete(at:)`. The target must be captured at *fast start*
(user could change settings mid-fast):

```swift
// In TimerViewModel — capture at start:
private var activeTargetHours: Double = 16.0

public func primaryAction() -> FastingStatus {
    switch status {
    case .idle, .completed, .abandoned:
        activeTargetHours = UserDefaults.standard.double(forKey: "atrest.fasting.targetHours")
        if activeTargetHours == 0 { activeTargetHours = 16.0 }
        status = machine.start(at: clock())
        // ...
    case .active:
        status = machine.complete(at: clock(), targetDurationHours: activeTargetHours)
        // ...
    }
}
```

This means `FastingSessionMachine.complete(at:targetDurationHours:)` must be extended:

```swift
public mutating func complete(at end: Date, targetDurationHours: Double = 16.0) -> FastingStatus {
    guard case let .active(period) = status else { return status }
    let endTime = max(end, period.start)
    let session = FastingSession(start: period.start, end: endTime,
                                 targetDurationHours: targetDurationHours)
    status = .completed(session)
    return status
}
```

### Where it's read

| Consumer | What it uses it for |
|---|---|
| `TreeMapper.trees(for:)` | 70% threshold: `session.targetDurationHours * 0.70` |
| `TimerViewModel.materializationProgress` | Progress: `elapsedHours / activeTargetHours` |
| `TimerScreen` (display) | Not displayed to user — the target is a reference, not a countdown |

### Persistence

`FastingSession.targetDurationHours` must be persisted in `SessionStore`. Since sessions
are encoded via `FastingSessionDTO` (private Codable struct in SessionStore.swift),
add `targetDurationHours` to the DTO:

```swift
private struct FastingSessionDTO: Codable, Equatable {
    var id: UUID
    var start: Date
    var end: Date
    var targetDurationHours: Double?  // Optional for migration — nil defaults to 16.0

    func domainModel() -> FastingSession {
        FastingSession(id: id, start: start, end: end,
                       targetDurationHours: targetDurationHours ?? 16.0)
    }
}
```

### `activeTargetHours` persistence during active fast

The `activeTargetHours` must survive app termination during an active fast. It should be
persisted alongside the `ActiveStateDTO`:

```swift
private struct ActiveStateDTO: Codable, Equatable {
    var start: Date
    var lastEvent: Date
    var targetDurationHours: Double  // ← add

    var period: FastingPeriod {
        FastingPeriod(start: start, lastEvent: lastEvent)
    }

    init(period: FastingPeriod, targetDurationHours: Double = 16.0) {
        self.start = period.start
        self.lastEvent = period.lastEvent
        self.targetDurationHours = targetDurationHours
    }
}
```

And `TimerViewModel.restorePersistedState()` must recover `activeTargetHours` from it.

---

## 5. Forest Canvas Bounds & Degradation

### Canvas height formula

```swift
let treeCount = viewModel.treeLayouts.count
let screenHeight = UIScreen.main.bounds.height
let minCanvasHeight = screenHeight * 1.5
let growthPerTree: CGFloat = 35  // canvas grows as trees accumulate
let canvasHeight = max(minCanvasHeight, CGFloat(treeCount) * growthPerTree + screenHeight * 0.5)
```

This means:
- 0 trees → canvas is 1.5× screen height (just sky)
- 10 trees → ~850pt + half screen
- 100 trees → ~3500pt + half screen (very scrollable)

### Empty forest (0 trees)

Show dusk sky with a few static decorative stars and a centered muted text:
`L10n.forestEmpty` → "Your forest grows here."
This is NOT in current Localizable.strings — add it:
```
"forest.empty" = "Your forest grows here.";
```

### One tree

Positioned at the foreground layer, center-bottom of canvas. One star above it.
No decorative stars. Let the single tree breathe.

### Many trees (100+)

Canvas grows linearly. Performance: use `LazyVStack` or manual Canvas rendering
if ForEach over ZStack becomes slow. Set a reasonable cap — e.g., show the most
recent 200 trees. Older trees are still persisted but not rendered.

### SVG loading failure

If `TreeShape.extractPathD(from:)` returns nil (malformed SVG, missing file):
- `TreeShape.path(in:)` returns `Path()` (empty path) → view renders as invisible
- This is invisible degradation — no crash, no error UI
- Log a warning: `print("[Atrest] Failed to load tree variant \(variantIndex)")`

### `Path(svgPath:)` limitations

Swift's `Path(svgPath:)` supports standard SVG path commands but may struggle with:
- Relative commands mixed with absolute
- Arc commands (`A`/`a`)
- Extremely long path strings

The 8 tree SVGs use compound paths (`M...z M...z`) with only `M`, `L`, `C`, `Q`, `Z` commands.
They should parse cleanly. If any fail, fall back to a simple oval shape:

```swift
public func path(in rect: CGRect) -> Path {
    guard !pathString.isEmpty else {
        // Fallback: simple tree-ish oval
        return Path(ellipseIn: rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.05))
    }
    var path = Path(svgPath: pathString)
    // ...normal scaling...
}
```

---

## 6. Animation Choreography

### Tree materialization (continuous during active fast)

Driven by `Timer.publish` in `TimerViewModel` — the existing `refresh()` method
already runs on a timer. `materializationProgress` is a computed property:

```swift
public var materializationProgress: Double {
    guard case .active = status else { return 0.0 }
    let target = activeTargetHours * 3600  // seconds
    guard target > 0 else { return 0.05 }
    let elapsed = durationHours * 3600
    return max(0.05, min(1.0, elapsed / target))
}
```

Since `status` is `@Published` and `durationHours` changes on each `refresh()`,
`materializationProgress` updates automatically. `TimerScreen` reacts via SwiftUI's
observation system — `TreeView`'s opacity and colour interpolate smoothly.

**No explicit `withAnimation` needed on the tree.** The tree's opacity and colour change
in small increments each refresh cycle (~1s intervals). SwiftUI's rendering handles smooth
interpolation of `Color` and `Double` opacity naturally. If you want *extra* smoothness,
wrap the `TreeView` in `.animation(Motion.slow, value: viewModel.materializationProgress)`.

### Arrival animation (star appearance on completion)

The star must appear once, on the transition from active → completed. Sequence:

1. `TimerViewModel.primaryAction()` is called → status changes to `.completed`
2. ViewModel sets `isJustCompleted = true`
3. `TimerScreen` observes `isJustCompleted`:

```swift
// In TimerScreen
.onChange(of: viewModel.isJustCompleted) { _, isComplete in
    if isComplete {
        // Star is already shown via showStar binding in TreeMaterializationView.
        // The tree stays at progress=1.0 since we keep the last computed value.
        // After a pause, reset so it doesn't replay:
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            viewModel.isJustCompleted = false
        }
    }
}
```

4. Inside `TreeMaterializationView`, the star uses `.transition(.opacity)` with
   `Motion.starAppear` (1.2s easeIn after 0.4s delay). This triggers automatically
   when `showStar` goes from false → true.

The key: `progress` must remain at `1.0` during the `.completed` state, not snap to `0.0`:

```swift
public var materializationProgress: Double {
    switch status {
    case .active:
        // ...calculated from elapsed/target...
    case .completed:
        return 1.0  // hold at full for arrival animation
    default:
        return 0.0
    }
}
```

### Forest parallax

Use `GeometryReader` + `PreferenceKey` pattern:

```swift
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// In ForestScreen:
ScrollView {
    ZStack(alignment: .top) {
        // Anchor to read offset
        GeometryReader { geo in
            Color.clear.preference(
                key: ScrollOffsetKey.self,
                value: geo.frame(in: .named("forestScroll")).minY
            )
        }
        .frame(height: 0)

        // Star layer — parallax at 30%
        starLayer
            .offset(y: -scrollOffset * 0.70)  // counter-scroll by 70% = moves at 30% speed

        // Tree layer — scrolls normally (1:1)
        treeLayer
    }
    .frame(height: canvasHeight)
}
.coordinateSpace(name: "forestScroll")
.onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
```

---

## 7. Files Not Mentioned in Main Handover

| File | Status | Action |
|---|---|---|
| `UI/EntitlementAdapters.swift` | Debug-only mock | **No changes.** Works as-is for previews. |
| `UI/ExportDocument.swift` | FileDocument for JSON export | **No changes.** Used by SettingsViewModel. |
| `Data/Entitlements.swift` | Full StoreKit 2 + Keychain stack | **No changes.** Already functional. |
| `Data/DataPortability.swift` | Export/import logic | **No changes.** |
| `Data/Placeholder.swift` | Empty placeholder | Can be deleted if desired. |
| `Domain/Placeholder.swift` | Empty placeholder | Can be deleted if desired. |
| `DesignSystem/Placeholder.swift` | Empty placeholder | Can be deleted if desired. |
| `Policy/Placeholder.swift` | Empty placeholder | Can be deleted if desired. |

---

## 8. Model Changes — Exact Diff Summary

### `FastingSession` (Models.swift)

```diff
  public struct FastingSession: Equatable {
      public let id: UUID
      public let start: Date
      public let end: Date
+     public let targetDurationHours: Double

-     public init(id: UUID = UUID(), start: Date, end: Date) {
+     public init(id: UUID = UUID(), start: Date, end: Date, targetDurationHours: Double = 16.0) {
          self.id = id
          self.start = start
          self.end = end
+         self.targetDurationHours = targetDurationHours
      }
  }
```

### `HistoryItem` (Models.swift)

```diff
  public struct HistoryItem: Equatable {
      public let session: FastingSession
-     public let isInspectable: Bool
-     public let isSilhouette: Bool
+     public let isInspectable: Bool    // kept for CalendarPolicy compat

-     public init(session: FastingSession, isInspectable: Bool, isSilhouette: Bool) {
+     public init(session: FastingSession, isInspectable: Bool) {
          self.session = session
          self.isInspectable = isInspectable
-         self.isSilhouette = isSilhouette
      }
  }
```

`isSilhouette` is removed — the new forest doesn't show silhouettes. Free tier simply
can't access the forest. All references to `isSilhouette` in `HistoryVisibilityPolicy`,
`ForestViewModel`, and tests must be updated.

### `CoreUtility` (Models.swift)

Delete the enum and `CoreUtilityPolicy` in PolicyRules.swift — unused in new design.

---

## 9. New Localizable.strings Keys Needed

The main handover's copy is done, but the supplement reveals a few missing keys:

```
/* Forest — empty state */
"forest.empty" = "Your forest grows here.";

/* Forest — back button a11y */
"forest.back" = "Return to timer";

/* Water inline — expanded state header */
"water.inline.header" = "Today";

/* Settings — target note */
"settings.fasting.note" = "This is a reference, not a goal.";
```

Add these to `Localizable.strings` and corresponding `L10n` properties to `Strings.swift`.

---

## 10. Test Impact Summary

| Test file | Impact |
|---|---|
| `FastingSessionMachineTests` | Update `complete()` calls to include `targetDurationHours` param |
| `TreeMappingTests` | Add tests for `.incomplete` state, 70% threshold, `targetDurationHours` |
| `MilestoneMappingTests` | Add 6th case (`prolongedFast`), update window assertions |
| `SessionStoreTests` | Verify `targetDurationHours` round-trips through persist/load |
| `EntitlementServiceTests` | Update for `TrialPolicy` change (no more `isNoticeDue`) |
| `PolicyRulesTests` | Update `TrialPolicy` assertions, remove `CoreUtilityPolicy` tests |
| `SnapshotTests` | Re-record all baselines with `isRecording = true` |
| `UnitHarnessTests` | May need update if it references `isSilhouette` |
