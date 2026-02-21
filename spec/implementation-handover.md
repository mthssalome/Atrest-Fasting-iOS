# Atrest — Comprehensive Implementation Handover

## Purpose

This document is the **sole authoritative brief** for implementing the Atrest redesign.
It replaces all prior handover documents. A fresh AI coding instance should read this
document AND all 7 doctrine files in `/doctrine/` before writing any code.

**All design decisions are final and locked.** Do not propose alternatives.
Implement exactly as specified. When in doubt, the doctrine file is the tiebreaker.

---

## Repository State

- **Branch:** work on `main` (or create `feature/redesign` from `main`)
- **Last commit:** `3378e9c` — doctrine overhaul + copy rewrite
- **Platform:** iOS 17+, SwiftUI, Swift Package Manager (no Xcode project file)
- **Module structure:** `Domain` → `Data`, `Policy`, `DesignSystem` → `UI` → `App`

### Doctrine Files (read ALL before starting)

| File | Governs |
|---|---|
| `doctrine/01-posture.md` | Voice character, no pressure, no evaluation |
| `doctrine/02-language.md` | Companion tone, biological curation rules, banned phrases |
| `doctrine/03-milestones.md` | 6 fasting phases with companion-toned biology |
| `doctrine/04-tree-forest.md` | Tree materialization, stars, forest layout, incomplete fasts |
| `doctrine/05-monetization-ethics.md` | 10-fast trial, transition moment, free/premium tiers, paywall surface |
| `doctrine/06-apple-ux.md` | Navigation architecture, aesthetic techniques, screen-by-screen specs, palettes |
| `doctrine/07-audience-positioning.md` | Implicit resonance principle, no explicit religious content |

### What Must Not Be Broken

- Domain logic: `FastingLogic.swift`, `Models.swift` (will be extended, not replaced)
- Data persistence: `SessionStore.swift`, `WaterStore.swift`, `DataPortability.swift`
- Policy scanner: `PolicyStringScanner` in `PolicyRules.swift`
- Policy tests: `Tests/PolicyTests/`
- Unit test harness: `Tests/UnitTests/UnitHarnessTests.swift`
- Snapshot test harness: `Tests/SnapshotTests/SnapshotHarnessTests.swift`
  (snapshot baselines WILL need re-recording after visual changes)

---

## Asset Inventory

**Location:** `Sources/DesignSystem/Resources/`
**Files:** `tree_0.svg` through `tree_7.svg`
- 8 SVG files, each a single `<path>`, `fill:#000000`, 1024×1024 viewBox
- Compound paths (multiple `z m` sub-paths = one unified silhouette)
- `Package.swift` already declares `.process("Resources")` for DesignSystem

---

## Implementation Plan

### Phase A: Domain Extensions

#### A1. Extend `Sources/Domain/Models.swift`

Add `targetDurationHours` to `FastingSession`:

```swift
public struct FastingSession: Equatable {
    public let id: UUID
    public let start: Date
    public let end: Date
    public let targetDurationHours: Double

    public init(id: UUID = UUID(), start: Date, end: Date, targetDurationHours: Double = 16.0) {
        self.id = id
        self.start = start
        self.end = end
        self.targetDurationHours = targetDurationHours
    }

    public var durationHours: Double {
        let interval = end.timeIntervalSince(start)
        return interval / 3600.0
    }
}
```

Also add a user-configurable fasting target (stored via UserDefaults or similar):
```swift
public enum FastingDefaults {
    @AppStorage("atrest.fasting.targetHours") public static var targetHours: Double = 16.0
}
```

Remove `CoreUtility` enum — it's unused in the new design.

#### A2. Extend `Sources/Domain/Trees.swift`

Current state: `TreeState` has only `.established`. Replace with:

```swift
public enum TreeState: Equatable {
    case established
    case incomplete
    case materializing(progress: Double)
}
```

Update `TreeMapper`:

```swift
public enum TreeMapper {
    public static func trees(for sessions: [FastingSession]) -> [TreeMemory] {
        sessions.compactMap { session in
            guard session.durationHours >= 4.0 else { return nil }
            let target = session.targetDurationHours
            if session.durationHours >= target {
                return TreeMemory(session: session, state: .established)
            } else if session.durationHours >= target * 0.70 {
                return TreeMemory(session: session, state: .incomplete)
            } else {
                return nil
            }
        }
    }
}
```

#### A3. Extend `Sources/Domain/Milestones.swift`

Current state: 5 cases. Replace with 6:

```swift
public enum FastingMilestone: Equatable {
    case digestionCompleting          // 0–4h
    case beginningToShift             // 4–8h
    case metabolicTransition          // 8–12h
    case deeperRhythm                 // 12–16h
    case extendedFast                 // 16–24h
    case prolongedFast                // 24h+
```

Update windows accordingly. The `extendedFast` window becomes `16..<24`,
and `prolongedFast` is `24+` (upperBound: nil).

---

### Phase B: Design System

#### B1. Replace `Sources/DesignSystem/Tokens.swift`

Replace the entire file. New content:

```swift
import SwiftUI
import UIKit

// MARK: - Colour Palette (doctrine/06-apple-ux.md)

public enum Palette {
    // Sky — atmospheric background canvas
    public static let deepNight    = Color(hex: "#0D0D1A")
    public static let duskBase     = Color(hex: "#1A1225")
    public static let horizonWarm  = Color(hex: "#2D1F0E")
    public static let horizonCool  = Color(hex: "#111827")

    // Functional aliases (used by existing UI — must remain)
    public static let canvas       = deepNight
    public static let surface      = Color(red: 0.12, green: 0.10, blue: 0.14)
    public static let stroke       = Color(red: 0.30, green: 0.25, blue: 0.33)
    public static let accent       = Color(red: 0.58, green: 0.55, blue: 0.65)
    public static let muted        = Color(red: 0.45, green: 0.42, blue: 0.50)
    public static let highlight    = Color(red: 0.88, green: 0.84, blue: 0.78)

    // Earth tones — tree tonal identities (index 0–4)
    public static let earthTones: [(dark: Color, light: Color)] = [
        (Color(hex: "#3D2B1F"), Color(hex: "#7A5C45")),   // 0: bark brown
        (Color(hex: "#C17F3A"), Color(hex: "#E8A94E")),   // 1: warm amber
        (Color(hex: "#3A4A35"), Color(hex: "#6B7F5E")),   // 2: moss-grey green
        (Color(hex: "#4A4E5A"), Color(hex: "#8A909E")),   // 3: cool stone
        (Color(hex: "#8B6914"), Color(hex: "#D4A825")),   // 4: ancient gold
    ]

    // Materialization start colour (cool grey)
    public static let treeGrey = Color(red: 0.55, green: 0.55, blue: 0.60)

    // Star
    public static let starLight = Color(hex: "#F0EDE6")
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    public static func interpolate(from: Color, to: Color, t: Double) -> Color {
        let t = max(0, min(1, t))
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]
        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * t
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * t
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * t
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Typography (doctrine/06-apple-ux.md)

public enum Typography {
    public static let title = Font.system(.largeTitle, design: .rounded).weight(.semibold)
    public static let heading = Font.system(.title3, design: .rounded).weight(.semibold)
    public static let body = Font.system(.body, design: .rounded)
    public static let label = Font.system(.callout, design: .rounded).weight(.medium)
    public static let caption = Font.system(.caption, design: .rounded)
    public static let elapsed = Font.system(size: 48, weight: .light, design: .rounded)
}

// MARK: - Spacing & Radii

public enum Spacing {
    public static let xs: CGFloat = 6
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 14
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 28
    public static let xxl: CGFloat = 44
}

public enum Radii {
    public static let soft: CGFloat = 12
    public static let pill: CGFloat = 22
}

// MARK: - Motion (doctrine/06-apple-ux.md — 300-600ms, organic)

public enum Motion {
    public static var ease: Animation {
        UIAccessibility.isReduceMotionEnabled ? .none : .easeInOut(duration: 0.4)
    }
    public static var slow: Animation {
        UIAccessibility.isReduceMotionEnabled ? .none : .easeInOut(duration: 0.6)
    }
    public static var arrival: Animation {
        UIAccessibility.isReduceMotionEnabled ? .none : .easeOut(duration: 1.2)
    }
    public static var starAppear: Animation {
        UIAccessibility.isReduceMotionEnabled ? .none : .easeIn(duration: 1.2).delay(0.4)
    }
}
```

#### B2. New file: `Sources/DesignSystem/DuskBackground.swift`

```swift
import SwiftUI

public struct DuskBackground: View {
    public init() {}
    public var body: some View {
        LinearGradient(
            colors: [Palette.horizonWarm, Palette.duskBase, Palette.deepNight],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}
```

#### B3. New file: `Sources/DesignSystem/TreeView.swift`

Renders an SVG tree variant with materialization progress. Uses `Path(svgPath:)` (iOS 16+).

```swift
import SwiftUI

public struct TreeView: View {
    let variantIndex: Int      // 0–7
    let toneIndex: Int         // 0–4
    let progress: Double       // 0.0–1.0
    let isIncomplete: Bool
    let size: CGFloat

    public init(variantIndex: Int, toneIndex: Int, progress: Double,
                isIncomplete: Bool, size: CGFloat) {
        self.variantIndex = variantIndex
        self.toneIndex = toneIndex
        self.progress = progress
        self.isIncomplete = isIncomplete
        self.size = size
    }

    public var body: some View {
        TreeShape(variantIndex: variantIndex)
            .fill(tintColor)
            .opacity(0.05 + progress * 0.95)
            .frame(width: size, height: size)
    }

    private var tintColor: Color {
        if isIncomplete { return Palette.treeGrey }
        let tone = Palette.earthTones[toneIndex % Palette.earthTones.count]
        return Color.interpolate(from: Palette.treeGrey, to: tone.light, t: progress)
    }
}
```

#### B4. New file: `Sources/DesignSystem/TreeShape.swift`

Loads SVG path string from bundle and renders as SwiftUI Shape:

```swift
import SwiftUI

public struct TreeShape: Shape {
    private let pathString: String

    public init(variantIndex: Int) {
        let name = "tree_\(variantIndex)"
        // Load SVG, extract the d="" attribute from the <path> element
        if let url = Bundle.module.url(forResource: name, withExtension: "svg"),
           let data = try? Data(contentsOf: url),
           let svg = String(data: data, encoding: .utf8),
           let dValue = TreeShape.extractPathD(from: svg) {
            self.pathString = dValue
        } else {
            self.pathString = ""
        }
    }

    public func path(in rect: CGRect) -> Path {
        guard !pathString.isEmpty else { return Path() }
        var path = Path(svgPath: pathString)
        let bounds = path.boundingRect
        guard bounds.width > 0, bounds.height > 0 else { return path }
        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        let transform = CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY)
            .scaledBy(x: scale, y: scale)
            .translatedBy(
                x: (rect.width / scale - bounds.width) / 2,
                y: (rect.height / scale - bounds.height) / 2
            )
        return path.applying(transform)
    }

    private static func extractPathD(from svg: String) -> String? {
        guard let range = svg.range(of: #"(?<=d=")[^"]*"#, options: .regularExpression) else {
            return nil
        }
        return String(svg[range])
    }
}
```

#### B5. New file: `Sources/DesignSystem/StarView.swift`

4-pointed compass star with radial glow (doctrine/04-tree-forest.md):

```swift
import SwiftUI

public struct StarView: View {
    public init() {}
    public var body: some View {
        ZStack {
            Capsule().fill(Palette.starLight).frame(width: 2, height: 18)
            Capsule().fill(Palette.starLight).frame(width: 2, height: 18)
                .rotationEffect(.degrees(90))
            Capsule().fill(Palette.starLight).frame(width: 1.5, height: 14)
                .rotationEffect(.degrees(45))
            Capsule().fill(Palette.starLight).frame(width: 1.5, height: 14)
                .rotationEffect(.degrees(135))
        }
        .shadow(color: Palette.starLight.opacity(0.6), radius: 8)
    }
}
```

#### B6. Replace `Sources/DesignSystem/TreeGlyph.swift`

The old Circle+Capsule placeholder is retired. Replace with a thin wrapper:

```swift
import SwiftUI
import Domain

public struct TreeGlyph: View {
    private let memory: TreeMemory
    private let isLocked: Bool
    private let accessibilityLabel: String

    public init(memory: TreeMemory, isLocked: Bool, accessibilityLabel: String) {
        self.memory = memory
        self.isLocked = isLocked
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        let variantIndex = abs(memory.session.id.hashValue) % 8
        let toneIndex = abs(memory.session.id.hashValue / 8) % 5
        let progress: Double = memory.state == .incomplete ? 0.30 : 1.0
        let incomplete = memory.state == .incomplete

        TreeView(
            variantIndex: variantIndex,
            toneIndex: toneIndex,
            progress: progress,
            isIncomplete: incomplete,
            size: 80
        )
        .opacity(isLocked ? 0.20 : 1.0)
        .accessibilityLabel(accessibilityLabel)
    }
}
```

Note: `accessibilityHint` parameter removed — the new L10n keys don't use it.

---

### Phase C: Navigation Architecture

This is the biggest structural change. The `TabView` in `RootView.swift` is completely replaced.

#### C1. Replace `Sources/UI/RootView.swift`

The new `RootView` implements the contextual navigation system (doctrine/06-apple-ux.md).

**Architecture:**

```
RootView
├── TimerScreen (always present, the home)
│   ├── [During active fast] EscapeHatchGlyph → overlay with 3 options
│   ├── [During active fast] WaterInlineElement
│   └── [During idle] FloatingNavIcons (forest, calendar, settings)
├── ForestScreen (fullscreen, crossfade transition, premium/trial only)
├── CalendarSheet (frosted glass sheet)
├── SettingsSheet (frosted glass sheet)
│   └── PaywallSheet (nested from settings)
└── TransitionMoment (one-time overlay after fast 10)
```

State management:
```swift
enum AppDestination {
    case timer
    case forest
    case calendar
    case settings
    case paywall
}
```

Navigation uses `@State private var destination: AppDestination = .timer`
with crossfade transitions (`.transition(.opacity)` + `withAnimation(Motion.slow)`).

**Key behaviours:**
- `TabView` is gone. No `tabItem` anywhere.
- Forest icon is hidden when user is on free tier post-trial (no forest access).
- Calendar opens for all users but shows 10-day window on free tier.
- The transition moment (after 10th fast) is presented as a fullscreen overlay — see `05-monetization`.
- The old `trialNotice` / `L10n.paywallTrialNotice` mechanism in `RootView` is removed entirely.

#### C2. New file: `Sources/UI/EscapeHatchOverlay.swift`

The frosted-glass overlay shown when tapping the Atrest glyph during active fast:

- 3 icons: forest glyph, calendar dot grid, settings gear (custom SVG)
- `.ultraThinMaterial` background
- Dismisses on tap-outside
- Does not show forest icon if user is post-trial free tier

#### C3. New file: `Sources/UI/FloatingNavIcons.swift`

The 3 muted floating icons shown during idle state at the bottom of the timer screen:

- Custom SVG icons, ~24pt, muted earth-tone stroke, no fill
- Opacity 40%, no labels, no background bar
- Tap triggers crossfade navigation to destination
- Does not show forest icon if user is post-trial free tier

#### C4. New file: `Sources/UI/TransitionMomentView.swift`

The one-time overlay after the 10th completed fast (doctrine/05-monetization):

- Full-screen frosted glass over dusk sky
- Atrest tree glyph at top, centered
- Transition body text (from `L10n.transitionBody`)
- Two equal-weight buttons: "Continue with Atrest" / "Maybe later"
- "Maybe later" dismisses instantly, no confirmation dialog
- Presented once. Dismissed state persisted (UserDefaults flag).
- "Continue" opens paywall sheet.

---

### Phase D: Screen Redesigns

#### D1. Replace `Sources/UI/TimerScreen.swift`

**Current state:** VStack of left-aligned text labels on flat black background.
**New state:** Centered, atmospheric, tree-focused.

Layout (doctrine/06-apple-ux.md, Timer Screen spec):
- `DuskBackground().ignoresSafeArea()` — replaces `Palette.canvas`
- During active fast (premium/trial): `TreeMaterializationView` centered in lower 60%
- During active fast (free post-trial): no tree, dusk sky only
- Elapsed time: large centered numerals using `Typography.elapsed`, format `12h 30m`
- Current milestone: companion text, centered, below time
- Water drop indicator: bottom area (see D5)
- Escape-hatch glyph: top-left, 30% opacity
- Action button: bottom, low-opacity pill
- Abandon button: appears only during active fast, below action button
- During idle: centered prompt "When you're ready", floating nav icons at bottom
- No title, no subtitle, no "State" label, no "Milestone" label, no "Elapsed" label

#### D2. New file: `Sources/UI/TreeMaterializationView.swift`

Renders the active fast's tree on the timer screen:

```swift
struct TreeMaterializationView: View {
    let variantIndex: Int
    let toneIndex: Int
    let progress: Double
    let showStar: Bool   // true when progress >= 1.0

    var body: some View {
        GeometryReader { geo in
            let treeSize = geo.size.width * 0.72
            let treeOriginY = geo.size.height * 0.28

            ZStack {
                TreeView(
                    variantIndex: variantIndex,
                    toneIndex: toneIndex,
                    progress: progress,
                    isIncomplete: false,
                    size: treeSize
                )
                .position(x: geo.size.width / 2, y: treeOriginY + treeSize / 2)

                if showStar {
                    StarView()
                        .frame(width: 18, height: 18)
                        .position(
                            x: geo.size.width / 2 + treeSize * 0.38,
                            y: treeOriginY + treeSize * 0.08
                        )
                        .transition(.opacity.animation(Motion.starAppear))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
```

#### D3. Replace `Sources/UI/ForestScreen.swift`

**Current state:** `LazyVGrid` 3-column flat grid with title/subtitle.
**New state:** Depth-layered free-positioned scrollable canvas (doctrine/04-tree-forest.md).

Two-layer canvas inside a `ScrollView`:
1. **Sky layer** — `DuskBackground` + `StarView` instances, parallax at 30% scroll speed
2. **Grove layer** — free-positioned trees at 3 depth layers

Layout constants:
```
treeSize:    foreground 80pt, mid 62pt, background 48pt
treeOpacity: foreground 1.0, mid 0.65, background 0.40
Depth Y bands (of canvas height):
  layer 0 (foreground): 55%–90%
  layer 1 (mid):        35%–65%
  layer 2 (background): 15%–45%
Star zone: upper 40% of canvas
```

Seeding rules (deterministic from session.id.hashValue):
- `variantIndex` = `abs(id.hashValue) % 8`
- `toneIndex` = `abs(id.hashValue / 8) % 5`
- `depthLayer` = index-in-array % 3
- `position.x` = seeded within `[treeWidth/2 ... canvasWidth - treeWidth/2]`
- `position.y` = seeded within depth layer's Y band
- `starPosition` = seeded across full width, upper 40% of height

The 3 floating navigation icons persist at bottom. Forest icon at higher opacity.
Back-swipe returns to timer.

No visible titles or subtitles. All text is accessibility-only.

#### D4. Replace `Sources/UI/CalendarScreen.swift`

**Current state:** `List` with "Entries" and "Locked" sections.
**New state:** Spatial month grid on frosted glass sheet (doctrine/06-apple-ux.md).

- Presented as sheet (`presentationDetents([.large])`) with `.ultraThinMaterial` background
- 7-column month grid, standard calendar layout
- Days with completed fasts: small earth-toned dot (matched to tree's tone index)
- Days with incomplete fasts: small grey dot
- Days without fasts: empty
- Tap a dot → detail overlay: date, duration (in `Xh Ym` format), "Completed" or "Ended early"
- Swipe between months
- Free tier: only shows dots for the 10 most recent fasting days. Older months show as empty grids.
  NO "locked" labels, NO "upgrade to see more", NO greyed-out dots.
- Title "Calendar" shown in compact navigation bar of the sheet.

#### D5. New file: `Sources/UI/WaterInlineView.swift`

Water is no longer a screen. It's an inline element on the timer screen during active fasts.

- Small custom SVG water drop glyph + today's total, near bottom of timer content
- Tap to expand: frosted chip with total, quick-add button, entry list with swipe-delete
- Collapse on tap-outside
- Only shown during active fast. Hidden during idle.
- Uses existing `WaterViewModel` — no changes to water data layer.

#### D6. Replace `Sources/UI/SettingsScreen.swift`

**Current state:** Crude `List` with Subscriptions and Data sections.
**New state:** Frosted glass sheet with 6 sections (doctrine/06-apple-ux.md).

Sections (in order):
1. **Fasting** — Target duration picker (12/14/16/18/20/24h or free text). Note: "This is a reference, not a goal."
2. **Hydration** — Unit preference (ml/oz), quick-add amount (150/200/250/300/500 or free text)
3. **Premium** — "Go premium" text link (only visible to free-tier post-trial users)
4. **Your data** — Export, Import, "Your data is stored only on this device."
5. **Account** — Manage subscription, Restore purchases (only visible to premium users)
6. **Legal** — Terms of Service, Privacy Policy links

Presented as sheet with `.ultraThinMaterial` background. Earth palette section headers.

#### D7. Replace `Sources/UI/PaywallScreen.swift`

**Current state:** Feature-gate language, "Select" buttons, "Premium access" title.
**New state:** Values surface on frosted glass (doctrine/05-monetization-ethics.md).

Layout (top to bottom):
1. Atrest tree glyph (small, centered, identity mark)
2. Values statement: `L10n.paywallValues`
3. Experiential description: `L10n.paywallDescription`
4. Two price options with equal visual weight:
   - Annual: `L10n.paywallAnnual` — tappable directly (no separate "Select" button)
   - Lifetime: `L10n.paywallLifetime` — tappable directly
5. Restore purchases link
6. Apple note: `L10n.paywallAppleNote`
7. Renewal disclosure: `L10n.paywallRenewalNote`
8. Footer links: Terms, Privacy

No feature comparison table. No "unlock" language. No "most popular" badge.

---

### Phase E: ViewModel Updates

#### E1. Extend `Sources/UI/TimerViewModel.swift`

Add these published properties:

```swift
// Materialization
public var materializationProgress: Double {
    guard case .active = status else { return 0.0 }
    let target = FastingDefaults.targetHours * 3600
    let elapsed = machine.durationHours * 3600
    return max(0.05, min(1.0, elapsed / target))
}

public var activeTreeVariantIndex: Int {
    // Seeded from session start time for determinism
    guard case let .active(period) = status else { return 0 }
    return abs(period.start.hashValue) % 8
}

public var activeTreeToneIndex: Int {
    guard case let .active(period) = status else { return 0 }
    return abs(period.start.hashValue / 8) % 5
}

public var isJustCompleted: Bool  // set true on completion, reset on next interaction
```

Update `statusLabel` to use new L10n keys:
```swift
public var statusLabel: String {
    switch status {
    case .idle: return L10n.timerIdlePrompt
    case .active: return L10n.timerActiveLabel
    case .completed: return L10n.timerCompletedLabel
    case .abandoned: return L10n.timerAbandonedLabel
    }
}
```

Update `milestoneLabel` to use new L10n keys (the new `FastingMilestone` cases map to new `L10n.milestone*` keys).

Update `primaryActionLabel`:
```swift
public var primaryActionLabel: String {
    switch status {
    case .idle, .completed, .abandoned: return L10n.timerActionBegin
    case .active: return L10n.timerActionEnd
    }
}
```

Remove `trialNotice` property — the trial notice mechanism is replaced by the transition moment.

#### E2. Extend `Sources/UI/ForestViewModel.swift`

Replace current implementation with layout computation:

```swift
public struct TreeLayout: Identifiable {
    public let id: UUID
    public let memory: TreeMemory
    public let position: CGPoint
    public let depthLayer: Int        // 0=foreground, 1=mid, 2=background
    public let toneIndex: Int         // 0–4
    public let variantIndex: Int      // 0–7
}

public struct StarLayout: Identifiable {
    public let id: UUID
    public let position: CGPoint
    public let depthLayer: Int
}
```

Compute layouts deterministically from session IDs. See Phase D3 for seeding rules.

The `HistoryItem` / `isLocked` / `isSilhouette` concept is simplified:
- Premium/trial: all trees shown with full presence
- Free tier: forest is not accessible (handled at navigation level, not here)

#### E3. Update `Sources/UI/CalendarViewModel.swift`

Keep the same structure but remove `lockedEntries` — on free tier, the calendar simply
receives only the 10 most recent entries from `CalendarPolicy`. The view model doesn't need
to distinguish "locked" from "visible" — it just shows what it gets.

#### E4. Update `Sources/UI/PaywallViewModel.swift`

Update L10n references:
- `L10n.paywallStatusIdle` → removed (no idle status display)
- `L10n.paywallStatusPurchasing` → `L10n.paywallStatusProcessing`
- `L10n.paywallStatusError` → `L10n.paywallStatusError`
- `L10n.paywallStatusSuccess` → `L10n.paywallStatusSuccess`

Remove `setStatusMessage` — no longer used for trial notices.

#### E5. Update `Sources/UI/SettingsViewModel.swift`

Add fasting target and hydration preferences:
- Read/write `FastingDefaults.targetHours`
- Read/write hydration unit preference (UserDefaults)
- Read/write quick-add amount (UserDefaults)

The existing export/import functionality stays. Update L10n references to new keys.

---

### Phase F: Policy Updates

#### F1. Update `Sources/Policy/PolicyRules.swift`

**`TrialPolicy`**: Currently returns `.trial` for ≤11 completions and has `isNoticeDue`.
Update to:
- First 10 completed fasts → `.trial` (full experience)
- 11th and beyond → `nil` (no trial entitlement; falls through to `.free` or `.premium`)
- Remove `isNoticeDue` — replaced by transition moment
- Add: `shouldShowTransitionMoment(completed:) -> Bool` — returns `true` when `completed == 10` AND the transition has not been dismissed (check UserDefaults flag)

**`CalendarPolicy`**: Update free tier — don't return "locked" entries. Just return the 10 most recent:
```swift
case .free:
    return persisted.prefix(10).map { session in
        CalendarEntry(sessionID: session.id, date: session.end, isInspectable: true)
    }
```

**`HistoryVisibilityPolicy`**: Simplify — free tier just gets empty array (forest not accessible).
Premium/trial gets full list.

Remove `CoreUtilityPolicy` — unused.

---

### Phase G: App Entry Point

#### G1. Update `Sources/App/AtrestApp.swift`

Remove `WaterScreen` standalone initialization — water is inline now.
The `WaterViewModel` still exists and is passed to the new `TimerScreen` (or `RootView`
passes it down).

Remove tab-related references. `RootView` no longer takes a `paywallViewModel` separately —
paywall is reached through settings.

---

### Phase H: Delete Unused Files

- `Sources/UI/WaterScreen.swift` — replaced by `WaterInlineView.swift`

---

### Phase I: Tests

1. All `Tests/PolicyTests/` must pass. Update test cases for modified `TrialPolicy` and `CalendarPolicy`.
2. Add unit tests for:
   - `TreeMapper` with `.incomplete` state and 70% threshold
   - New `FastingMilestone` cases (6 instead of 5)
   - `TrialPolicy.shouldShowTransitionMoment`
3. Update `Tests/UnitTests/TreeMappingTests.swift` and `Tests/UnitTests/MilestoneMappingTests.swift`.
4. Snapshot tests will need re-recording: run with `isRecording = true` on a simulator.

---

## Copy Reference

All strings are already written in `Sources/UI/Resources/Localizable.strings`
and `Sources/UI/Strings.swift` (committed at `3378e9c`). L10n keys are already
updated. The implementation instance does NOT need to write new copy — only
wire the existing L10n keys into the views.

Key mapping for milestones (new enum cases → new L10n keys):
```
.digestionCompleting  → L10n.milestoneDigestionCompleting
.beginningToShift     → L10n.milestoneBeginningToShift
.metabolicTransition  → L10n.milestoneMetabolicTransition
.deeperRhythm         → L10n.milestoneDeeperRhythm
.extendedFast         → L10n.milestoneExtendedFast
.prolongedFast        → L10n.milestoneProlongedFast
```

---

## Implementation Order (Recommended)

```
A1. Models.swift — add targetDurationHours
A2. Trees.swift — add TreeState cases, update TreeMapper
A3. Milestones.swift — 6 phases
B1. Tokens.swift — full palette + Color(hex:) + interpolate + new Motion
B2. DuskBackground.swift — new file
B3. TreeView.swift — new file
B4. TreeShape.swift — new file (SVG loader)
B5. StarView.swift — new file
B6. TreeGlyph.swift — replace with TreeView wrapper
C1. RootView.swift — replace TabView with contextual nav
C2. EscapeHatchOverlay.swift — new file
C3. FloatingNavIcons.swift — new file
C4. TransitionMomentView.swift — new file
D1. TimerScreen.swift — full redesign
D2. TreeMaterializationView.swift — new file
D3. ForestScreen.swift — full redesign
D4. CalendarScreen.swift — full redesign
D5. WaterInlineView.swift — new file (replaces WaterScreen)
D6. SettingsScreen.swift — full redesign
D7. PaywallScreen.swift — full redesign
E1. TimerViewModel.swift — materialization props, L10n updates
E2. ForestViewModel.swift — layout computation
E3. CalendarViewModel.swift — simplify
E4. PaywallViewModel.swift — L10n updates
E5. SettingsViewModel.swift — preferences
F1. PolicyRules.swift — trial, calendar, history policy updates
G1. AtrestApp.swift — remove tab wiring
H1. Delete WaterScreen.swift
I1. Run tests, update unit tests, re-record snapshots
```

---

## Custom SVG Icons Required

The following custom SVG icons must be created (Recraft V3 Vector Art or hand-drawn,
matching Atrest's organic aesthetic):

| Icon | Used For | Size | Style |
|---|---|---|---|
| Atrest glyph (tree+star) | Escape hatch, paywall identity | ~28pt | Single-path, organic |
| Forest tree silhouette | Navigation glyph | ~24pt | Simplified tree form, stroke only |
| Calendar dot grid | Navigation glyph | ~24pt | 3×3 or 4×3 dot arrangement |
| Settings stone/gear | Navigation glyph | ~24pt | Organic gear or smooth stone form |
| Water drop | Inline water indicator | ~16pt | Organic drop, slightly imperfect |

These should be added to `Sources/DesignSystem/Resources/` as SVG files.
Until custom icons are available, placeholder SF Symbols can be used temporarily
with a `// TODO: Replace with custom SVG` comment.

---

## What This Handover Does NOT Cover

These are deferred to future phases:

- **Christian depth layer** (reflections toggle, verse at completion, seasonal awareness)
- **Onboarding / first-run experience** (beyond the first-fast glyph pulse)
- **App Store listing copy and screenshots**
- **Widget / Live Activity**
- **Social / community features**
- **Push notification strategy**

---

## Verification Checklist

After implementation is complete, verify:

- [ ] No `TabView` or `tabItem` anywhere in the codebase
- [ ] No L10n keys from the old set referenced (old `timer.title`, `tab.*`, `paywall.trial.notice`, etc.)
- [ ] No "unlock", "locked", "silhouette", "inspectable" language in UI
- [ ] Tree materializes during active fast (premium/trial), absent on free tier
- [ ] Forest accessible only during trial and premium
- [ ] Transition moment appears exactly once after 10th fast
- [ ] Transition "Maybe later" dismisses with zero friction
- [ ] Paywall contains values statement, no feature comparison table
- [ ] Settings has 6 sections: Fasting, Hydration, Premium, Data, Account, Legal
- [ ] Calendar is month grid with dots, not a list
- [ ] Water is inline on timer screen, not a separate tab/screen
- [ ] All biological milestones use companion tone from Localizable.strings
- [ ] `DuskBackground` used on timer and forest screens
- [ ] Frosted glass used on calendar, settings, paywall sheets
- [ ] All policy tests pass
- [ ] All unit tests pass
- [ ] Snapshot tests re-recorded
