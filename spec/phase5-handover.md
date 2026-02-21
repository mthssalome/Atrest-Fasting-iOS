# Phase 5 — Technical Implementation Handover

## Purpose

This document is the authoritative brief for a fresh AI coding instance to implement
Phase 5 (Craft, Visual System & Atmosphere) of the Atrest iOS fasting app.

All design decisions are final and locked. Do not re-derive, re-question, or propose
alternatives to anything specified here. Implement exactly as written.

All doctrine files in `/doctrine/` are binding constraints. Read them before touching any file.

---

## Repository State at Handover

- **Branch:** `feature/phase5-visuals`
- **Base:** `main` at commit `848b9cb` ("Add tree assets and refine doctrine")
- **Platform:** iOS 17+, SwiftUI, Swift Package Manager (no Xcode project file)
- **Module structure:** `Domain`, `Data`, `DesignSystem`, `UI`, `Policy`, `App`

### What already exists and must not be broken

- All domain logic: `FastingLogic.swift`, `Models.swift`, `Milestones.swift`, `Trees.swift`
- All data persistence: `SessionStore.swift`, `WaterStore.swift`, `DataPortability.swift`
- All policy rules and tests: `PolicyRules.swift`, `Tests/PolicyTests/`
- All unit tests: `Tests/UnitTests/`
- Navigation wiring: `RootView.swift`, `AtrestApp.swift`
- Non-visual screens (untouched): `CalendarScreen`, `WaterScreen`, `SettingsScreen`, `PaywallScreen`
- Snapshot test harness: `Tests/SnapshotTests/` (baselines will need re-recording after visual changes)

---

## Asset Inventory

**Location:** `Sources/DesignSystem/Resources/`
**Files:** `tree_0.svg` through `tree_7.svg` — 8 SVG files, each a single `<path>` element,
`fill:#000000`, square 1024×1024 viewBox, compound path (multiple `z m` sub-paths = one unified silhouette).

`Package.swift` already declares:
```swift
.target(
    name: "DesignSystem",
    dependencies: ["Domain"],
    resources: [.process("Resources")]
)
```
At runtime, load via `Bundle.module.url(forResource: "tree_0", withExtension: "svg")`.

---

## Files to Replace Entirely

### 1. `Sources/DesignSystem/Tokens.swift`
Current state: flat near-black palette, no atmospheric tokens.
Replace with full two-palette system. See "Palette Specification" below.

### 2. `Sources/DesignSystem/TreeGlyph.swift`
Current state: `Circle()` + `Capsule()` placeholder geometry.
Replace with SVG-path-based `TreeShape` renderer. See "Tree Rendering Specification" below.

### 3. `Sources/UI/ForestScreen.swift`
Current state: `LazyVGrid` 3-column flat grid.
Replace with depth-layered free-positioned scrollable canvas + star sky layer.
See "Forest Screen Specification" below.

---

## Files to Extend

### 4. `Sources/Domain/Trees.swift`
Current state:
```swift
public enum TreeState: Equatable {
    case established
}
```
Add two states:
```swift
public enum TreeState: Equatable {
    case established                          // completed fast, full tonal presence
    case incomplete                           // ≥70% but <100% of target duration
    case materializing(progress: Double)      // 0.0–1.0, active fast on timer screen
}
```
Update `TreeMapper` — currently filters `durationHours >= 4.0`. Add incomplete logic:
a session that ended early but reached ≥70% of its target duration also produces a tree
with `state: .incomplete`. The target duration comes from the session's fasting goal
(if unavailable, default target = 16 hours). Sessions below 70% of target OR below 4h minimum
produce no tree.

### 5. `Sources/UI/ForestViewModel.swift`
Current state: exposes `trees: [TreePresentation]` array only.
Extend with:
- `treeLayouts: [TreeLayout]` — seeded position, depth layer, tonal index for each tree
- `starLayouts: [StarLayout]` — seeded position for each completed fast's star
- `canvasSize: CGSize` — the total virtual canvas size (width: screen width, height: dynamic)

Add new structs:
```swift
public struct TreeLayout: Identifiable {
    public let id: UUID
    public let memory: TreeMemory
    public let isLocked: Bool
    public let position: CGPoint         // absolute position within canvas
    public let depthLayer: Int           // 0 = foreground, 1 = mid, 2 = background
    public let toneIndex: Int            // 0–4, maps to earth palette
    public let variantIndex: Int         // 0–7, maps to tree_N.svg
}

public struct StarLayout: Identifiable {
    public let id: UUID                  // same as session id
    public let position: CGPoint         // absolute position, upper 40% of canvas height
    public let depthLayer: Int           // same depth logic as trees
}
```

Seeding rules (deterministic, no randomness — use session.id's hash):
- `variantIndex` = `abs(session.id.hashValue) % 8`
- `toneIndex` = `abs(session.id.hashValue) % 5`
- `depthLayer` = index-in-array % 3 (cycle through layers as trees accumulate)
- `position.x` = seeded float in range `[treeWidth/2 ... canvasWidth - treeWidth/2]`
- `position.y` = seeded float within depth layer's height band (see Forest spec)
- `starPosition.x` = seeded float across full canvas width
- `starPosition.y` = seeded float in upper 40% of canvas height

### 6. `Sources/UI/TimerScreen.swift`
Current state: VStack of text labels, no visual focal point.
Extend — do not replace the existing text layout. Insert a `TreeMaterializationView`
into the existing `ZStack` body, positioned as a background layer behind the content VStack.
See "Timer Screen Specification" below.

---

## Files to Touch Lightly

### 7. `Sources/UI/TimerViewModel.swift`
Expose `materializationProgress: Double` — computed from `elapsedSeconds / targetSeconds`,
clamped to `0.05...1.0`. Only meaningful when status is `.active`. Return `0.0` otherwise.

### 8. `Sources/Domain/Models.swift`
`FastingSession` currently has no `targetDuration`. Add:
```swift
public let targetDurationHours: Double  // default 16.0 if not set
```
This is needed by tree incomplete-fast detection and materialization progress.

---

## Palette Specification

### Replace `Sources/DesignSystem/Tokens.swift` — Palette section

```swift
public enum Palette {
    // Sky — background canvas
    public static let deepNight    = Color(hex: "#0D0D1A")
    public static let duskBase     = Color(hex: "#1A1225")
    public static let horizonWarm  = Color(hex: "#2D1F0E")
    public static let horizonCool  = Color(hex: "#111827")

    // Functional aliases (used throughout existing UI — must remain)
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

    // Materialization start colour (cool grey — incomplete/in-progress trees)
    public static let treeGrey = Color(red: 0.55, green: 0.55, blue: 0.60)

    // Star
    public static let starLight = Color(hex: "#F0EDE6")
}
```

Add a `Color(hex:)` convenience initialiser in an extension (standard hex-to-Color pattern).

Add `DuskBackground` view — a `LinearGradient` from `horizonWarm` at bottom to `duskBase`
at top, with an extremely slow `.animation` that never actually triggers changes in v1.
This replaces all `Palette.canvas.ignoresSafeArea()` calls in `TimerScreen` and `ForestScreen`.

---

## Tree Rendering Specification

### New file: `Sources/DesignSystem/TreeShape.swift`

```swift
// TreeShape loads the SVG path string for a given variant index (0–7)
// and renders it as a SwiftUI Shape that fills its frame proportionally.
// The path data is read once at init from Bundle.module.
// SVG viewBox is always 1024×1024.
```

`TreeShape` conforms to `Shape`. Its `path(in:)` method:
1. Parses the SVG `d` attribute from the cached path string
2. Scales the path from `1024×1024` to the given `rect` using `CGAffineTransform`
3. Returns the scaled `Path`

Use `SwiftSVG` or manual `Path(svgPath:)` parsing — Swift 5.9+ has `Path(svgPath:)` available on iOS 16+. Since target is iOS 17, use `Path(svgPath:)` directly.

### New view: `Sources/DesignSystem/TreeView.swift`

```swift
public struct TreeView: View {
    let variantIndex: Int      // 0–7
    let toneIndex: Int         // 0–4
    let progress: Double       // 0.0–1.0 (materialization)
    let isIncomplete: Bool     // true = stays grey, never warms
    let size: CGFloat          // frame size (square)
```

Rendering logic:
- `opacity` = `0.05 + (progress * 0.95)` — ranges from near-invisible to fully present
- `tintColor`: if `isIncomplete`, use `Palette.treeGrey`. Otherwise interpolate linearly
  between `Palette.treeGrey` and `Palette.earthTones[toneIndex].light` using `progress`.
  Use `Color.interpolate(from:to:t:)` helper.
- Apply tint via `.colorMultiply(tintColor)`
- `.frame(width: size, height: size)`
- No animations inside this view — caller drives changes

---

## Timer Screen Specification

### Modified: `Sources/UI/TimerScreen.swift`

The existing content VStack is preserved exactly. Insert a `TreeMaterializationView`
in the `ZStack` beneath it, plus replace `Palette.canvas.ignoresSafeArea()` with
`DuskBackground().ignoresSafeArea()`.

```swift
ZStack {
    DuskBackground().ignoresSafeArea()
    TreeMaterializationView(
        variantIndex: viewModel.activeTreeVariantIndex,   // seeded from session start
        toneIndex: viewModel.activeTreeToneIndex,
        progress: viewModel.materializationProgress
    )
    content   // existing VStack — unchanged
}
```

### New view: `Sources/UI/TreeMaterializationView.swift`

This view renders the active fast's tree, centered in the lower 60% of the screen,
plus a `StarView` that appears at the top-right of the tree bounding box when
`progress >= 1.0`.

```swift
struct TreeMaterializationView: View {
    let variantIndex: Int
    let toneIndex: Int
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let treeSize: CGFloat = geo.size.width * 0.72
            let treeOriginY = geo.size.height * 0.28

            ZStack(alignment: .topLeading) {
                TreeView(
                    variantIndex: variantIndex,
                    toneIndex: toneIndex,
                    progress: progress,
                    isIncomplete: false,
                    size: treeSize
                )
                .position(x: geo.size.width / 2, y: treeOriginY + treeSize / 2)

                if progress >= 1.0 {
                    StarView()
                        .frame(width: 18, height: 18)
                        .position(
                            x: geo.size.width / 2 + treeSize * 0.38,
                            y: treeOriginY + treeSize * 0.08
                        )
                        .transition(.opacity.animation(.easeIn(duration: 1.2).delay(0.4)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
```

### New view: `Sources/DesignSystem/StarView.swift`

A 4-pointed compass star — two thin `Capsule` shapes, one vertical, one rotated 45°,
overlapping at centre. Both filled with `Palette.starLight`. A `.shadow(color: Palette.starLight.opacity(0.6), radius: 8)` applied to the `ZStack` gives the radial glow.

```swift
public struct StarView: View {
    public var body: some View {
        ZStack {
            Capsule()
                .fill(Palette.starLight)
                .frame(width: 2, height: 18)
            Capsule()
                .fill(Palette.starLight)
                .frame(width: 2, height: 18)
                .rotationEffect(.degrees(90))
            Capsule()
                .fill(Palette.starLight)
                .frame(width: 1.5, height: 14)
                .rotationEffect(.degrees(45))
            Capsule()
                .fill(Palette.starLight)
                .frame(width: 1.5, height: 14)
                .rotationEffect(.degrees(135))
        }
        .shadow(color: Palette.starLight.opacity(0.6), radius: 8)
    }
}
```

---

## Forest Screen Specification

### Replace: `Sources/UI/ForestScreen.swift`

Two-layer canvas inside a `ScrollView`:
1. **Sky layer** (ZStack, covers full canvas, parallax-scrolled)
2. **Grove layer** (ZStack, free-positioned trees)

#### Layout constants
```
canvasWidth  = UIScreen width
treeSize     = 80pt (foreground), 62pt (mid), 48pt (background)
treeOpacity  = 1.0 (foreground), 0.65 (mid), 0.40 (background)

Depth layer Y bands (of total canvas height):
  layer 0 (foreground): 55%–90%
  layer 1 (mid):        35%–65%
  layer 2 (background): 15%–45%

Star zone: upper 40% of canvas height (y: 0 to canvasHeight * 0.40)
```

#### Parallax implementation
Stars scroll at 30% the speed of trees. Use a `PreferenceKey` to read scroll offset,
then apply `.offset(y: scrollOffset * 0.30)` to the star layer.

Or simpler: use `GeometryReader` inside a `ScrollView` to derive offset, apply to star `ZStack`.

#### Scroll anchor
On first render and when trees are added, scroll to bring the most recently added trees
(highest Y position = foreground) into view. Use `ScrollViewReader` with `.scrollTo(latestTreeID)`.

#### Per-tree rendering
```swift
ForEach(viewModel.treeLayouts) { layout in
    TreeView(
        variantIndex: layout.variantIndex,
        toneIndex: layout.toneIndex,
        progress: layout.memory.state == .incomplete ? 0.30 : 1.0,
        isIncomplete: layout.memory.state == .incomplete,
        size: treeSize(for: layout.depthLayer)
    )
    .opacity(treeOpacity(for: layout.depthLayer))
    .position(layout.position)
    .zIndex(Double(2 - layout.depthLayer))  // foreground trees on top
}
```

#### Per-star rendering
```swift
ForEach(viewModel.starLayouts) { star in
    StarView()
        .frame(width: 10, height: 10)
        .opacity(starOpacity(for: star.depthLayer))
        .position(star.position)
        .scaleEffect(starScale(for: star.depthLayer))
}
.offset(y: scrollOffset * 0.30)  // parallax
```

Incomplete fasts: tree renders at 30% opacity, cool grey. No star. Follows same depth rules.
Locked (free tier silhouettes): renders at 20% opacity, coolest grey, blurred slightly
(`.blur(radius: 1.5)`).

---

## Arrival Animation Specification

When a fast completes and the user is on the TimerScreen, trigger this sequence:
1. `progress` animates from current value to `1.0` over `1.2s` with `.easeOut`
2. After 400ms delay: `StarView` fades in with `1.2s` `.easeIn`

This is driven by `TimerViewModel` publishing `isJustCompleted: Bool`.
`TreeMaterializationView` observes this and triggers the animation chain once.

The transition to `ForestScreen` (tab navigation) is not automated. The user navigates
themselves after seeing the completion. No forced navigation.

---

## Domain Extension: `Trees.swift`

The incomplete fast rule:
- A session qualifies for an incomplete tree if:
  `durationHours >= 4.0 AND durationHours >= (targetDurationHours * 0.70)`
  AND `durationHours < targetDurationHours`
- Sessions with `durationHours < 4.0` produce NO tree regardless
- Sessions that meet or exceed `targetDurationHours` produce `.established` tree

Updated `TreeMapper.trees(for:)`:
```swift
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
```

---

## What Must Not Change

- `TreeMapper` filter threshold of `4.0` hours minimum — preserved above
- History visibility limit (free tier: 10 inspectable) — unchanged, lives in `PolicyRules.swift`
- No tree size, brightness, or decoration that implies one fast is better than another
- No streak references anywhere
- No urgency language in any new strings
- `CalendarScreen`, `WaterScreen`, `SettingsScreen`, `PaywallScreen` — untouched
- All existing `Tests/` — must remain passing. Snapshot tests will need re-recording.

---

## Test Considerations

After implementing visual changes:
1. `UIScreenSnapshotTests.swift` has `isRecording = true` already — snapshot baselines
   will auto-regenerate on first test run on a Mac with a simulator.
2. Policy tests (`Tests/PolicyTests/`) must continue to pass without modification.
3. Unit tests (`Tests/UnitTests/TreeMappingTests.swift`) will need cases added for
   `.incomplete` state and the 70% threshold logic.

---

## Implementation Order (Recommended)

1. Extend `Models.swift` — add `targetDurationHours` to `FastingSession`
2. Extend `Trees.swift` — add `TreeState` cases and updated `TreeMapper`
3. Update `Tokens.swift` — replace palette, add `DuskBackground`, add `Color(hex:)` extension
4. Create `TreeShape.swift` — SVG path loader and SwiftUI Shape
5. Create `StarView.swift` — 4-pointed star with glow
6. Create `TreeView.swift` — composite view with opacity + colorMultiply materialization
7. Extend `ForestViewModel.swift` — add layout seeding for trees and stars
8. Create `TreeMaterializationView.swift` — timer screen tree layer
9. Extend `TimerViewModel.swift` — add `materializationProgress`, `activeTreeVariantIndex`,
   `activeTreeToneIndex`, `isJustCompleted`
10. Modify `TimerScreen.swift` — insert tree layer into ZStack, replace background
11. Replace `ForestScreen.swift` — full depth-layered canvas implementation
12. Replace `TreeGlyph.swift` — now delegates to `TreeView` (kept for backwards compat
    with snapshot test references, but renders via `TreeView` internally)
13. Run tests, re-record snapshots

---

## Branch Hygiene

Work on `feature/phase5-visuals`. When complete, open PR against `main`.
Do not merge to main without all tests passing.
Do not push intermediate broken states to origin.
