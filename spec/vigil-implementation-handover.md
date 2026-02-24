# Vigil Implementation Handover

> **Date:** 2026-02-24
> **Purpose:** Complete implementation specification for the Vigil depth layer.
> A separate AI coding instance should be able to implement entirely from this document
> plus the doctrine files it references.
>
> **Binding doctrine:** `doctrine/08-depth-layer.md` (content, visual spec, rules)
> **Aesthetic reference:** `doctrine/06-apple-ux.md` (palette, typography, motion, surface treatment)
> **Role directive:** Implement exactly what is specified. Do not add features. Do not rephrase copy.

---

## Table of Contents

1. [Scope Summary](#1-scope-summary)
2. [Module Map — What Changes Where](#2-module-map)
3. [Phase A — Data Layer: Vigil Toggle Persistence](#3-phase-a)
4. [Phase B — Design System: Vigil Typography & Motion Tokens](#4-phase-b)
5. [Phase C — Vigil Content Provider](#5-phase-c)
6. [Phase D — Localizable Strings](#6-phase-d)
7. [Phase E — Settings Screen: Vigil Section](#7-phase-e)
8. [Phase F — Timer Screen: Milestone Scripture + Fast Start](#8-phase-f)
9. [Phase G — Forest Screen: Inscription](#9-phase-g)
10. [Phase H — Idle State: Daily Fragment](#10-phase-h)
11. [Phase I — Arrival: Completion Scripture](#11-phase-i)
12. [Phase J — Long-Press Citation Reveal](#12-phase-j)
13. [Phase K — Tests](#13-phase-k)
14. [Checklist](#14-checklist)

---

<a id="1-scope-summary"></a>
## 1. Scope Summary

Vigil is an opt-in content layer activated by a single `UserDefaults` boolean.
When active, it adds Scripture fragments and contemplative language at specific touchpoints.
It changes **no mechanics, no navigation, no visual elements** of the existing experience.
It adds **text only** — rendered in a specific typographic register (the "star register").

### What ships

| Touchpoint | Content pieces | Notes |
|---|---|---|
| Idle daily fragment | 10 rotating | Changed daily by day-of-year modulo |
| Fast start line | 1 fixed | Fades in/out over ~4s |
| Milestone companion additions | 6 | One per fasting phase, extends default text |
| Milestone Scripture fragments | 6 | One per phase, below companion text |
| Arrival Scripture | 5 rotating | Per-fast index modulo |
| Forest inscription | 1 fixed | Viewport-anchored, bottom edge |
| Incomplete fast | 0 | Intentionally silent |
| Calendar | 0 | No change |
| **Total** | **29** | |

### What does NOT ship

- Seasonal awareness (Lent, Advent)
- Community presence numbers
- Rotating idle library beyond 10 fragments
- Any visual changes to trees, stars, forest, gradients, or navigation

---

<a id="2-module-map"></a>
## 2. Module Map — What Changes Where

```
Domain/          — No changes
Data/            — No changes
Policy/          — No changes
DesignSystem/
  Tokens.swift   — ADD Vigil typography + motion tokens
UI/
  Strings.swift           — ADD ~40 new L10n keys for Vigil content
  Resources/
    Localizable.strings   — ADD ~40 new string entries
  SettingsScreen.swift    — ADD Vigil section (between Hydration and Premium)
  SettingsViewModel.swift — ADD @AppStorage for vigil toggle
  TimerScreen.swift       — ADD milestone Scripture, fast-start overlay, idle fragment
  TimerViewModel.swift    — ADD vigil-aware milestone label, fast start index
  ForestScreen.swift      — ADD inscription anchored to bottom
  RootView.swift          — No changes (Vigil is not a navigation concern)
  NEW: VigilContentProvider.swift — Centralized Vigil content logic
  NEW: ScriptureFragmentView.swift — Reusable Scripture display component
  NEW: CitationRevealModifier.swift — Long-press gesture + citation overlay
```

**No new modules. No new dependencies. No Package.swift changes.**

---

<a id="3-phase-a"></a>
## 3. Phase A — Data Layer: Vigil Toggle Persistence

### File: `Sources/UI/SettingsViewModel.swift`

Add one `@AppStorage` property alongside the existing ones:

```swift
@AppStorage("atrest.vigil.enabled") public var isVigilEnabled: Bool = false
```

**Key:** `atrest.vigil.enabled`
**Default:** `false` (Vigil is off by default, always)
**Location:** same class (`SettingsViewModel`), alongside `targetHours`, `hydrationUnitRaw`, `quickAddAmount`

This is the single source of truth. All UI reads this value via `SettingsViewModel`
or directly via `@AppStorage("atrest.vigil.enabled")` where the view model isn't available.

---

<a id="4-phase-b"></a>
## 4. Phase B — Design System: Vigil Typography & Motion Tokens

### File: `Sources/DesignSystem/Tokens.swift`

#### Palette addition

Add to the `Palette` enum, after the existing `starLight`:

```swift
// Vigil — Scripture shares the star's visual register
public static let scriptureText = starLight.opacity(0.60)
public static let citationText  = starLight.opacity(0.40)
```

#### Typography additions

Add to the `Typography` enum:

```swift
// Vigil — inscription register (doctrine/08-depth-layer.md Visual Specification)
public static let scripture = Font.system(.callout, design: .serif).weight(.light)
    .leading(.loose)
public static let citation  = Font.system(.caption2, design: .serif).weight(.light)
```

**Design notes:**
- `.serif` distinguishes Scripture from the `.rounded` companion text — a different voice
- `.light` weight — lighter than the `.regular` companion body text
- `.leading(.loose)` — generous line height per doctrine
- Custom tracking (letter-spacing) is applied in the view via `.tracking(1.2)` for Scripture
  and `.tracking(1.6)` for citations

#### Motion additions

Add to the `Motion` enum:

```swift
// Vigil animations (doctrine/08-depth-layer.md Visual Specification)
public static var scriptureFadeIn: Animation {
    UIAccessibility.isReduceMotionEnabled ? .none : .easeOut(duration: 0.6)
}
public static var scriptureFadeOut: Animation {
    UIAccessibility.isReduceMotionEnabled ? .none : .easeIn(duration: 0.8)
}
public static var scriptureDelayed: Animation {
    UIAccessibility.isReduceMotionEnabled ? .none : .easeOut(duration: 0.4).delay(0.4)
}
public static var citationReveal: Animation {
    UIAccessibility.isReduceMotionEnabled ? .none : .easeOut(duration: 0.3)
}
public static var citationDismiss: Animation {
    UIAccessibility.isReduceMotionEnabled ? .none : .easeIn(duration: 0.5)
}
```

---

<a id="5-phase-c"></a>
## 5. Phase C — Vigil Content Provider

### NEW File: `Sources/UI/VigilContentProvider.swift`

A pure-logic utility (no SwiftUI views) that returns Vigil content for each touchpoint.
All content is hardcoded — no network, no database, no file loading.

```swift
import Foundation
import Domain

public enum VigilContentProvider {

    // MARK: - Types

    public struct ScriptureFragment {
        public let text: String          // The paraphrased fragment
        public let citation: String      // "Psalm 46" — book and chapter only
    }

    public struct MilestoneVigilContent {
        public let companionAddition: String   // Extends the biological text
        public let scripture: ScriptureFragment
    }

    // MARK: - Idle Daily Fragment

    /// Returns the Scripture fragment for today. Changes daily, not per visit.
    /// Uses day-of-year modulo to cycle through the library.
    public static func idleFragment(for date: Date = Date()) -> ScriptureFragment {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % idleFragments.count
        return idleFragments[index]
    }

    // MARK: - Fast Start

    /// Fixed companion line shown at fast start. NOT Scripture.
    public static let fastStartLine = NSLocalizedString(
        "vigil.fastStart",
        bundle: .module,
        comment: "Vigil: companion line at fast start"
    )

    // MARK: - Milestones

    /// Returns the Vigil content for a given milestone.
    public static func milestoneContent(for milestone: FastingMilestone) -> MilestoneVigilContent {
        switch milestone {
        case .digestionCompleting:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.digestionCompleting.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.digestionCompleting.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.digestionCompleting.citation", bundle: .module, comment: "")
                )
            )
        case .beginningToShift:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.beginningToShift.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.beginningToShift.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.beginningToShift.citation", bundle: .module, comment: "")
                )
            )
        case .metabolicTransition:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.metabolicTransition.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.metabolicTransition.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.metabolicTransition.citation", bundle: .module, comment: "")
                )
            )
        case .deeperRhythm:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.deeperRhythm.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.deeperRhythm.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.deeperRhythm.citation", bundle: .module, comment: "")
                )
            )
        case .extendedFast:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.extendedFast.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.extendedFast.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.extendedFast.citation", bundle: .module, comment: "")
                )
            )
        case .prolongedFast:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.prolongedFast.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.prolongedFast.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.prolongedFast.citation", bundle: .module, comment: "")
                )
            )
        }
    }

    // MARK: - Arrival

    /// Returns the arrival Scripture fragment for the given completed fast index.
    /// Cycles through 5 fragments.
    public static func arrivalFragment(fastIndex: Int) -> ScriptureFragment {
        let index = abs(fastIndex) % arrivalFragments.count
        return arrivalFragments[index]
    }

    // MARK: - Forest Inscription

    public static let forestInscription = ScriptureFragment(
        text: NSLocalizedString("vigil.forest.inscription", bundle: .module, comment: ""),
        citation: NSLocalizedString("vigil.forest.inscription.citation", bundle: .module, comment: "")
    )

    // MARK: - Private Data

    private static let idleFragments: [ScriptureFragment] = [
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.0", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.0.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.1", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.1.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.2", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.2.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.3", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.3.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.4", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.4.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.5", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.5.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.6", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.6.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.7", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.7.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.8", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.8.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.9", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.9.citation", bundle: .module, comment: "")
        ),
    ]

    private static let arrivalFragments: [ScriptureFragment] = [
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.0", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.0.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.1", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.1.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.2", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.2.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.3", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.3.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.4", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.4.citation", bundle: .module, comment: "")
        ),
    ]
}
```

**Notes:**
- All text is routed through `NSLocalizedString` / `Localizable.strings` — same pattern as existing `L10n`
- The content provider is stateless, pure — easy to test
- Fast index for arrival rotation: use `completedCount` from `SessionStoreState` modulo 5

---

<a id="6-phase-d"></a>
## 6. Phase D — Localizable Strings

### File: `Sources/UI/Resources/Localizable.strings`

Add the following section **after** the Navigation accessibility section at the end of the file:

```
/* ----------------------------------------------------------
   Vigil — Depth Layer  (doctrine: 08-depth-layer)
   Scripture fragments. Companion additions. No commentary.
   ---------------------------------------------------------- */

/* Settings */
"vigil.section.title"   = "Vigil";
"vigil.section.explanation" = "Adds Scripture and reflective language throughout your fasting experience.";

/* Fast start — companion line (not Scripture) */
"vigil.fastStart" = "You have set this time apart.";

/* Milestone companion additions */
"vigil.milestone.digestionCompleting.companion" = "For now, it is simply a choice — a quiet setting-apart of hours.";
"vigil.milestone.beginningToShift.companion" = "What was received is now being tended — drawn from gently.";
"vigil.milestone.metabolicTransition.companion" = "This is often where choosing to remain becomes its own quiet practice.";
"vigil.milestone.deeperRhythm.companion" = "Not only the body finds a rhythm — something quieter settles alongside it.";
"vigil.milestone.extendedFast.companion" = "For thousands of years, fasting this long has been understood as a way of making room.";
"vigil.milestone.prolongedFast.companion" = "Be attentive to how you feel — and to what else surfaces in the stillness.";

/* Milestone Scripture fragments */
"vigil.milestone.digestionCompleting.scripture" = "This is the day.";
"vigil.milestone.digestionCompleting.citation" = "Psalm 118";
"vigil.milestone.beginningToShift.scripture" = "I shall not want.";
"vigil.milestone.beginningToShift.citation" = "Psalm 23";
"vigil.milestone.metabolicTransition.scripture" = "When you pass through, I will be with you.";
"vigil.milestone.metabolicTransition.citation" = "Isaiah 43";
"vigil.milestone.deeperRhythm.scripture" = "Be still, and know.";
"vigil.milestone.deeperRhythm.citation" = "Psalm 46";
"vigil.milestone.extendedFast.scripture" = "Not by bread alone.";
"vigil.milestone.extendedFast.citation" = "Matthew 4";
"vigil.milestone.prolongedFast.scripture" = "Search me, and know my heart.";
"vigil.milestone.prolongedFast.citation" = "Psalm 139";

/* Arrival Scripture fragments (5, rotating per fast) */
"vigil.arrival.0" = "In every season, it yields its fruit.";
"vigil.arrival.0.citation" = "Revelation 22";
"vigil.arrival.1" = "What was begun in you is being carried to completion.";
"vigil.arrival.1.citation" = "Philippians 1";
"vigil.arrival.2" = "To everything, a season.";
"vigil.arrival.2.citation" = "Ecclesiastes 3";
"vigil.arrival.3" = "The Lord bless you, and keep you.";
"vigil.arrival.3.citation" = "Numbers 6";
"vigil.arrival.4" = "You prepare a table before me.";
"vigil.arrival.4.citation" = "Psalm 23";

/* Idle daily fragments (10, rotating by day-of-year) */
"vigil.idle.0" = "The earth is full of your steadfast love.";
"vigil.idle.0.citation" = "Psalm 119";
"vigil.idle.1" = "Morning by morning, new mercies.";
"vigil.idle.1.citation" = "Lamentations 3";
"vigil.idle.2" = "The heavens declare.";
"vigil.idle.2.citation" = "Psalm 19";
"vigil.idle.3" = "He leads me beside still waters.";
"vigil.idle.3.citation" = "Psalm 23";
"vigil.idle.4" = "In him all things hold together.";
"vigil.idle.4.citation" = "Colossians 1";
"vigil.idle.5" = "Great is your faithfulness.";
"vigil.idle.5.citation" = "Lamentations 3";
"vigil.idle.6" = "Your hands have made and fashioned me.";
"vigil.idle.6.citation" = "Psalm 119";
"vigil.idle.7" = "Even the darkness is not dark to you.";
"vigil.idle.7.citation" = "Psalm 139";
"vigil.idle.8" = "In returning and rest you shall be saved.";
"vigil.idle.8.citation" = "Isaiah 30";
"vigil.idle.9" = "Consider the birds of the air.";
"vigil.idle.9.citation" = "Matthew 6";

/* Forest inscription (permanent, not rotating) */
"vigil.forest.inscription" = "Consider how they grow.";
"vigil.forest.inscription.citation" = "Luke 12";

/* Accessibility */
"vigil.a11y.scripture" = "Scripture: %@";
"vigil.a11y.citation" = "From %@";
```

### File: `Sources/UI/Strings.swift`

Add a new `MARK` section for Vigil keys:

```swift
// MARK: - Vigil (Depth Layer)

public static let vigilSectionTitle = tr("vigil.section.title", "Vigil section header in settings")
public static let vigilSectionExplanation = tr("vigil.section.explanation", "Vigil toggle explanation")
public static let vigilFastStart = tr("vigil.fastStart", "Vigil: fast start companion line")
```

**Note:** Most Vigil strings are accessed through `VigilContentProvider` using `NSLocalizedString` directly,
so they don't all need `L10n` wrappers. Only the settings UI strings need `L10n` constants.

---

<a id="7-phase-e"></a>
## 7. Phase E — Settings Screen: Vigil Section

### File: `Sources/UI/SettingsScreen.swift`

Insert a new section **between** the Hydration section and the Premium section.
Find the closing `}` of the Hydration `sectionCard` and add:

```swift
sectionCard(title: L10n.vigilSectionTitle) {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        Toggle(isOn: Binding(
            get: { viewModel.isVigilEnabled },
            set: { viewModel.isVigilEnabled = $0 }
        )) {
            Text(L10n.vigilSectionExplanation)
                .font(Typography.caption)
                .foregroundStyle(Palette.muted)
        }
        .tint(Palette.accent)
    }
}
```

**Visual treatment:**
- Same `sectionCard` helper as all other settings sections (frosted glass `.ultraThinMaterial`)
- Section title "Vigil" in `Typography.heading` + `Palette.highlight` (handled by `sectionCard`)
- Toggle uses `Palette.accent` tint — consistent with segmented controls in Hydration section
- Explanation text is `Typography.caption` + `Palette.muted` — same as target note in Fasting section
- The toggle label IS the explanation — not a separate element above it

**Placement in the section order:**
1. Fasting (target duration)
2. Hydration (unit, quick-add)
3. **Vigil** ← NEW
4. Premium (post-trial, free tier only)
5. Data
6. Account (premium only)
7. Legal

---

<a id="8-phase-f"></a>
## 8. Phase F — Timer Screen: Milestone Scripture + Fast Start Line

### New File: `Sources/UI/ScriptureFragmentView.swift`

A reusable view for displaying a Scripture fragment in the star register.

```swift
import SwiftUI
import DesignSystem

public struct ScriptureFragmentView: View {
    let text: String
    let citation: String

    @State private var showCitation = false

    public init(text: String, citation: String) {
        self.text = text
        self.citation = citation
    }

    public var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(text)
                .font(Typography.scripture)
                .tracking(1.2)
                .foregroundStyle(Palette.scriptureText)
                .multilineTextAlignment(.center)
                .accessibilityLabel(String(format: L10n.vigilA11yScripture, text))

            if showCitation {
                Text(citation)
                    .font(Typography.citation)
                    .tracking(1.6)
                    .foregroundStyle(Palette.citationText)
                    .transition(.opacity)
                    .accessibilityLabel(String(format: L10n.vigilA11yCitation, citation))
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation(Motion.citationReveal) {
                showCitation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(Motion.citationDismiss) {
                    showCitation = false
                }
            }
        }
    }
}
```

**Notes:**
- No background surface. Text floats directly over the gradient.
- `tracking(1.2)` = wider letter-spacing for inscription feel
- Citation tracking is even wider (`1.6`) — a whisper below an inscription
- Long-press triggers 2-second reveal, then auto-dismisses
- `L10n.vigilA11yScripture` and `L10n.vigilA11yCitation` need to be added to Strings.swift:

```swift
public static let vigilA11yScripture = tr("vigil.a11y.scripture", "Scripture accessibility format")
public static let vigilA11yCitation = tr("vigil.a11y.citation", "Citation accessibility format")
```

### File: `Sources/UI/TimerScreen.swift`

#### Modification 1: Read Vigil state

Add an `@AppStorage` property to `TimerScreen`:

```swift
@AppStorage("atrest.vigil.enabled") private var isVigilEnabled: Bool = false
```

#### Modification 2: Milestone companion + Scripture

Currently, the milestone text is a single `Text(viewModel.milestoneLabel)` view.
When Vigil is active, this becomes the biological text + companion addition + Scripture fragment.

Replace the milestone text block (find the `if let milestone = viewModel.milestone` block):

```swift
if let milestone = viewModel.milestone {
    // Biological companion text (always shown)
    Text(viewModel.milestoneLabel)
        .font(Typography.body)
        .foregroundStyle(Palette.accent)
        .multilineTextAlignment(.center)
        .padding(.horizontal, Spacing.xl)
        .padding(.top, milestoneTextTopPadding(for: milestone))

    // Vigil: companion addition + Scripture
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
        .padding(.top, Spacing.md)
        .transition(.opacity)
        .animation(Motion.scriptureDelayed, value: milestone)
    }
}
```

**Key behavior:**
- Biological text updates immediately on phase transition (existing behavior)
- Companion addition appears with standard `.ease` animation
- Scripture fragment fades in 400ms delayed (`.scriptureDelayed`) — per doctrine visual spec
- Both are centered, generous horizontal padding, star-register color

#### Modification 3: Fast start overlay

When a fast starts and Vigil is active, show the companion line for ~4 seconds.

Add a `@State` property to `TimerScreen`:

```swift
@State private var showFastStartLine = false
```

In the `content` ZStack, add an overlay that shows when a fast begins:

```swift
if showFastStartLine && isVigilEnabled {
    Text(VigilContentProvider.fastStartLine)
        .font(Typography.scripture)
        .tracking(1.2)
        .foregroundStyle(Palette.scriptureText)
        .multilineTextAlignment(.center)
        .transition(.opacity)
        .padding(.horizontal, Spacing.xl)
}
```

Trigger it when status changes to `.active`. Add an `onChange` handler:

```swift
.onChange(of: viewModel.status) { oldStatus, newStatus in
    if case .active = newStatus, case .idle = oldStatus {
        // Fast just started
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
}
```

**Timing:**
- Fade in: 600ms ease-out (via `scriptureFadeIn`)
- Hold: ~2.5 seconds
- Fade out: 800ms ease-in (via `scriptureFadeOut`)
- Total: ~4 seconds
- Positioned in the center area of the screen, above the timer content

#### Modification 4: Idle state daily fragment

In the idle state block, add the daily fragment below the idle prompt:

```swift
if case .idle = viewModel.status {
    Text(L10n.timerIdlePrompt)
        .font(Typography.body)
        .foregroundStyle(Palette.accent)
        .padding(.bottom, isVigilEnabled ? Spacing.md : Spacing.md)

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
```

---

<a id="9-phase-g"></a>
## 9. Phase G — Forest Screen: Inscription

### File: `Sources/UI/ForestScreen.swift`

Add an `@AppStorage` property:

```swift
@AppStorage("atrest.vigil.enabled") private var isVigilEnabled: Bool = false
```

Add the forest inscription **anchored to the bottom of the viewport** (not scrolling with trees).
In the main `ZStack`, after the tree/star content and before the back button:

```swift
if isVigilEnabled && !viewModel.treeLayouts.isEmpty {
    VStack {
        Spacer()
        ScriptureFragmentView(
            text: VigilContentProvider.forestInscription.text,
            citation: VigilContentProvider.forestInscription.citation
        )
        .padding(.bottom, Spacing.xxl + Spacing.lg) // above the floating nav area
    }
    .allowsHitTesting(true) // only the text responds to long-press
}
```

**Key behavior:**
- Viewport-anchored (in the ZStack, not in the ScrollView)
- Only shown when Vigil is on AND the forest has trees (no inscription on an empty forest)
- Small, muted, at the bottom edge — inscription on the frame, not in the painting
- No animation — always there, like an inscription on a wall

---

<a id="10-phase-h"></a>
## 10. Phase H — Idle State: Daily Fragment

Already addressed in Phase F, Modification 4. The idle fragment is part of `TimerScreen.swift`.

**Rotation logic:** `VigilContentProvider.idleFragment(for:)` uses
`Calendar.current.ordinality(of: .day, in: .year, for: date)` modulo 10
to select from the 10-fragment library. The user sees the same fragment
all day regardless of how many times they open the app.

---

<a id="11-phase-i"></a>
## 11. Phase I — Arrival: Completion Scripture

### File: `Sources/UI/TimerScreen.swift`

When `viewModel.isJustCompleted` is true AND Vigil is active,
show the arrival Scripture fragment.

The arrival fragment needs to appear **after** the star.
The existing `isJustCompleted` flag is set when a fast completes and reset after 3 seconds.
We need the Scripture to appear 800ms after the star appears.

Add a `@State` property:

```swift
@State private var showArrivalScripture = false
```

In the existing `onChange(of: viewModel.isJustCompleted)`:

```swift
.onChange(of: viewModel.isJustCompleted) { _, isComplete in
    if isComplete {
        if isVigilEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(Motion.scriptureFadeIn) {
                    showArrivalScripture = true
                }
            }
        }
        // Note: do NOT auto-dismiss isJustCompleted after 3s anymore
        // when Vigil is active — let the user stay with the completion screen.
        // Only dismiss when they take an action (tap begin, navigate away).
        if !isVigilEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                viewModel.isJustCompleted = false
            }
        }
    } else {
        showArrivalScripture = false
    }
}
```

In the `content` view, add the arrival Scripture when completed:

```swift
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
```

**Note on `completedFastCount`:** The `TimerViewModel` needs a new property to expose
the count for arrival rotation. Add to `TimerViewModel`:

```swift
public var completedFastCount: Int?
```

This is set from `RootView.updateDerivedData` — pass `state.completedCount` to the view model.
Add in `RootView.updateDerivedData`:

```swift
timerViewModel.completedFastCount = state.completedCount
```

---

<a id="12-phase-j"></a>
## 12. Phase J — Long-Press Citation Reveal

Already implemented within `ScriptureFragmentView` (Phase F).
The long-press gesture and 2-second citation reveal are built into the reusable component.
Every touchpoint that uses `ScriptureFragmentView` automatically gets this interaction.

**Summary of interaction:**
1. Long-press (0.5s minimum) on any Scripture fragment
2. Citation fades in (300ms ease-out) below the fragment text
3. Holds for 2 seconds
4. Citation fades out (500ms ease-in)
5. Typography: caption2 serif light, tracking 1.6, star-register color at 40% opacity

---

<a id="13-phase-k"></a>
## 13. Phase K — Tests

### File: `Tests/UnitTests/VigilContentProviderTests.swift` (NEW)

```swift
import XCTest
@testable import UI
import Domain

final class VigilContentProviderTests: XCTestCase {

    // MARK: - Idle Fragment Rotation

    func testIdleFragmentReturnsSameFragmentForSameDay() {
        let date = Date()
        let a = VigilContentProvider.idleFragment(for: date)
        let b = VigilContentProvider.idleFragment(for: date)
        XCTAssertEqual(a.text, b.text)
        XCTAssertEqual(a.citation, b.citation)
    }

    func testIdleFragmentChangesNextDay() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let a = VigilContentProvider.idleFragment(for: today)
        let b = VigilContentProvider.idleFragment(for: tomorrow)
        // They may coincidentally match if library wraps, but in a 10-item library
        // consecutive days should differ
        XCTAssertNotEqual(a.text, b.text)
    }

    // MARK: - Milestone Content

    func testAllMilestonesHaveContent() {
        let milestones: [FastingMilestone] = [
            .digestionCompleting, .beginningToShift, .metabolicTransition,
            .deeperRhythm, .extendedFast, .prolongedFast
        ]
        for milestone in milestones {
            let content = VigilContentProvider.milestoneContent(for: milestone)
            XCTAssertFalse(content.companionAddition.isEmpty, "\(milestone) missing companion addition")
            XCTAssertFalse(content.scripture.text.isEmpty, "\(milestone) missing scripture text")
            XCTAssertFalse(content.scripture.citation.isEmpty, "\(milestone) missing citation")
        }
    }

    func testMilestoneCitationsAreBookChapterOnly() {
        let milestones: [FastingMilestone] = [
            .digestionCompleting, .beginningToShift, .metabolicTransition,
            .deeperRhythm, .extendedFast, .prolongedFast
        ]
        for milestone in milestones {
            let citation = VigilContentProvider.milestoneContent(for: milestone).scripture.citation
            // Citations should not contain ":" (verse separator)
            XCTAssertFalse(citation.contains(":"), "Citation '\(citation)' should not have verse numbers")
        }
    }

    // MARK: - Arrival Rotation

    func testArrivalFragmentCycles() {
        let a = VigilContentProvider.arrivalFragment(fastIndex: 0)
        let b = VigilContentProvider.arrivalFragment(fastIndex: 5)
        // Index 0 and 5 should give the same fragment (5 items, modulo 5)
        XCTAssertEqual(a.text, b.text)
    }

    func testArrivalFragmentDiffersByIndex() {
        let a = VigilContentProvider.arrivalFragment(fastIndex: 0)
        let b = VigilContentProvider.arrivalFragment(fastIndex: 1)
        XCTAssertNotEqual(a.text, b.text)
    }

    // MARK: - Forest Inscription

    func testForestInscriptionIsNotEmpty() {
        XCTAssertFalse(VigilContentProvider.forestInscription.text.isEmpty)
        XCTAssertFalse(VigilContentProvider.forestInscription.citation.isEmpty)
    }
}
```

### Existing Test Updates

No existing tests should break. The Vigil toggle defaults to `false`,
so all current behavior is preserved. Vigil is purely additive.

### Snapshot Tests

If time permits, add snapshot variants for:
- Timer screen with Vigil ON, active fast at 12–16h milestone
- Idle screen with Vigil ON (showing daily fragment)
- Forest screen with Vigil ON (showing inscription)

These use the existing `SnapshotTests` infrastructure with `.ultraThinMaterial` sheets.

---

<a id="14-checklist"></a>
## 14. Checklist

Before declaring the implementation complete, verify:

- [ ] Vigil toggle defaults to OFF
- [ ] Turning Vigil ON adds contemplative text to all 6 milestone phases
- [ ] Turning Vigil ON adds Scripture fragments below milestones
- [ ] Turning Vigil ON shows daily fragment on idle screen
- [ ] Turning Vigil ON shows "You have set this time apart." at fast start (fades ~4s)
- [ ] Turning Vigil ON shows arrival Scripture after star appears (800ms delay)
- [ ] Turning Vigil ON shows "Consider how they grow." on forest screen
- [ ] Turning Vigil OFF removes all Vigil content immediately (no stale text)
- [ ] Long-press on any Scripture fragment reveals book+chapter for 2 seconds
- [ ] Scripture text uses serif light font, star-register color at 60% opacity
- [ ] Citation text uses caption2 serif, star-register color at 40% opacity
- [ ] No Scripture appears for incomplete fasts
- [ ] No Scripture appears on calendar screen
- [ ] No Vigil content appears for users who never enable the toggle
- [ ] The Vigil setting persists across app launches
- [ ] The Vigil toggle is free — no entitlement gating
- [ ] All animations respect `UIAccessibility.isReduceMotionEnabled`
- [ ] All Scripture fragments have accessibility labels
- [ ] No existing tests broken
- [ ] New `VigilContentProviderTests` pass

---

## Files Created (3)

| File | Purpose |
|---|---|
| `Sources/UI/VigilContentProvider.swift` | Centralized content logic for all Vigil touchpoints |
| `Sources/UI/ScriptureFragmentView.swift` | Reusable SwiftUI component for Scripture display + long-press |
| `Tests/UnitTests/VigilContentProviderTests.swift` | Content provider unit tests |

## Files Modified (8)

| File | Change |
|---|---|
| `Sources/DesignSystem/Tokens.swift` | Add `Palette.scriptureText`, `Palette.citationText`, `Typography.scripture`, `Typography.citation`, Vigil `Motion` tokens |
| `Sources/UI/Strings.swift` | Add `L10n` keys for Vigil settings + accessibility |
| `Sources/UI/Resources/Localizable.strings` | Add ~40 Vigil string entries |
| `Sources/UI/SettingsScreen.swift` | Add Vigil section with toggle |
| `Sources/UI/SettingsViewModel.swift` | Add `@AppStorage` for Vigil boolean |
| `Sources/UI/TimerScreen.swift` | Add milestone Scripture, fast-start overlay, idle fragment, arrival Scripture |
| `Sources/UI/TimerViewModel.swift` | Add `completedFastCount` property |
| `Sources/UI/ForestScreen.swift` | Add viewport-anchored inscription |

## Files Unchanged

| File | Why |
|---|---|
| `Sources/UI/RootView.swift` | One line addition only: pass `completedCount` to timer view model |
| `Sources/Domain/*` | No domain model changes needed |
| `Sources/Data/*` | No data layer changes needed |
| `Sources/Policy/*` | No policy changes needed — Vigil is not entitlement-gated |
| `Package.swift` | No new modules or dependencies |
