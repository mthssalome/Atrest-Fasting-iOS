# Aesthetic Doctrine

## The Feeling This App Must Produce

Atrest opens at the end of the day.
The room is quiet. The user has chosen to be still.

The app must meet them in that stillness —
not as a tool, not as a coach, but as a space.
Like stepping outside at dusk into cool air.
Like a room with one lamp and no noise.

Every screen is a threshold into that space.
Every visual element exists to deepen it or must be removed.

---

## Visual Character

The visual language of Atrest is:

**Earthy. Dim. Organic.**

The palette lives at the boundary of darkness and warmth —
deep soil tones, bark, the green-black of a forest at night,
with moments of amber or pale morning light used sparingly and with intention.

Surfaces must have material weight. They do not feel like screens.
They feel like something you could touch.

Geometric primitives (circles, rectangles, capsules) are not sufficient.
Every icon, glyph, and decorative element must feel hand-considered —
as if a person drew it slowly, not a compiler generated it.

---

## Hierarchy of Attention

Each screen has one thing that the eye is meant to rest on.
One. Everything else recedes.

The Timer screen's resting point is time itself — its passage, its texture.
The Forest screen's resting point is the forest — its accumulated quiet.
All other screens are functional. Make them clean and forgettable.

---

## Motion

Motion in Atrest communicates one thing: time is passing, and that is enough.

Animations are:
- Slow (300–600ms unless a gesture demands immediacy)
- Organic (ease curves that breathe, not snap)
- Passive (the app moves on its own, subtly, when the user is not touching it)

Motion is never:
- Celebratory
- Urgent
- Attention-seeking

The background is always slightly alive. Almost imperceptibly.
The user should feel it before they see it.

---

## Typography

Type is atmosphere, not signage.

Use generous line-height and letter-spacing.
Titles should feel like they are resting on the page, not asserting themselves.
Numbers — especially elapsed time — should be large, quiet, and unhurried.

Never use default font weight for primary content. Adjust until the text
feels like it belongs to the space, not imposed on it.

---

## Colour Palette

Two distinct palettes operate in the same space and must never be conflated.

### Sky Palette — atmosphere, background, the canvas itself
| Role | Hex | Feeling |
|---|---|---|
| Deep night | `#0D0D1A` | The deepest forest hour |
| Dusk base | `#1A1225` | Where the sky lives |
| Horizon warm | `#2D1F0E` | The last light at the edge |
| Horizon cool | `#111827` | Before dawn, before colour |

The background drifts imperceptibly between horizon warm and horizon cool.
The drift is not time-of-day simulation — it is ambient atmosphere only.

### Earth Palette — trees, organic forms, tonal identity
Each tree receives one tonal identity seeded by session start time (mod 5).
No tone implies superiority over another.

| Index | Name | Range |
|---|---|---|
| 0 | Bark brown | `#3D2B1F` → `#7A5C45` |
| 1 | Warm amber | `#C17F3A` → `#E8A94E` |
| 2 | Moss-grey green | `#3A4A35` → `#6B7F5E` |
| 3 | Cool stone | `#4A4E5A` → `#8A909E` |
| 4 | Ancient gold | `#8B6914` → `#D4A825` |

During materialization, a tree's tone begins as cool grey (`rgb 55% 55% 60%`)
and warms toward its assigned earth tone as `elapsed / targetDuration` approaches 1.
An incomplete fast (≥70%, <100%) freezes permanently at cool grey.

### Star
Stars are not assigned a palette tone.
A star is a single point of near-white light (`#F0EDE6`) with a soft radial glow.
It belongs to neither the sky nor the earth — it is its own register.

---

## Navigation Architecture

Atrest does not use a standard iOS tab bar.

A 5-tab `TabView` treats every screen as equal. They are not.
The Timer + Tree is the experience. Everything else is secondary.
Navigation must reflect this hierarchy — not by hiding things,
but by making the primary experience feel immersive and the secondary
spaces feel like quiet rooms you step into when you choose.

### The Two Navigation States

#### During an Active Fast: Full Immersion

When a fast is running, the timer screen is all there is.
No tab bar. No navigation chrome. No bottom icons.

The user is *in* the experience — the tree materializing,
the dusk sky behind it, the biological companion text, the elapsed time.

A single **escape hatch** exists: a small Atrest glyph (the tree+star mark)
in the top-left corner of the screen. ~28pt. Opacity 30%. It does not
call attention to itself. It is there for the user who knows what it is.

**Tapping the glyph** reveals a minimal overlay — not a menu, not a sheet.
A frosted-glass surface with 3–4 quietly presented options:

- **Forest** (icon: tree silhouette glyph)
- **Calendar** (icon: small dot grid)
- **Settings** (icon: minimal gear or stone glyph)
- **Water** — presented inline on the timer screen itself (see Water section)

This overlay dismisses on tap-outside or swipe-down.

**First-time discovery:** On the user's very first fast, the glyph pulses
once, gently (opacity 30% → 50% → 30%, over 2 seconds) after 30 seconds.
Never again. The user learns the escape hatch exists. After that, it's quiet.

#### During Idle State: Gentle Orientation

When no fast is active (idle, completed, or abandoned), the timer screen
shows a resting state. In this state, 3 small floating icons appear
at the bottom of the screen:

- **Forest glyph** — a simplified tree form
- **Calendar glyph** — a small dot-grid
- **Settings glyph** — a stone or gear form

These are:
- Custom SVG icons (not SF Symbols)
- ~24pt, muted earth-tone stroke, no fill
- Opacity 40%
- Spaced evenly, no labels, no background bar
- Not a `TabView` or `UITabBar` — just positioned shapes that respond to tap

They float above the dusk gradient. They are part of the atmosphere,
not bolted onto it.

Tapping any icon navigates with a crossfade transition (not a push or slide).
The dusk palette persists across all screens — the user never leaves the world.

### Inside Secondary Screens

**Forest:** Full-screen canvas. The same 3 floating icons persist at the bottom
(with forest highlighted at slightly higher opacity). Back-swipe also returns to timer.

**Calendar and Settings:** Presented as a frosted-glass sheet rising over the
dusk background. The atmospheric world is visible underneath, blurred.
A standard back gesture (swipe down or back arrow) returns to the previous screen.
The bottom icons are NOT shown — these screens are "inside" the overlay,
not at the same navigation level as timer and forest.

**Paywall:** Presented as a frosted-glass sheet from Settings. Same treatment
as calendar and settings — an overlay on the world, not a separate place.

### Water: Inline on Timer Screen

Water tracking is not a navigation destination. It lives on the timer screen.

During an active fast, a small **water drop indicator** appears near the bottom
of the timer content — showing today's total in ml/oz. Tapping it opens a
minimal inline expansion (not a sheet, not a new screen):
- Today's total
- A "+250ml" (or configured amount) quick-add button
- A small list of today's entries with swipe-to-delete

This expansion collapses on tap-outside. Water is a utility within the fast,
not a place you go.

During idle state, the water indicator is not shown (no active fast to hydrate during).

### Navigation Rules

1. The timer screen is always home. Every path leads back to it.
2. No screen transition should feel like leaving. The atmosphere persists.
3. Tab bars, segmented controls, and bottom navigation bars are banned.
4. Navigation elements are organic shapes at low opacity — part of the world.
5. Labels on navigation elements are banned. Icons only. Accessibility labels provided.
6. The active-fast timer screen has exactly one interactive navigation element: the escape-hatch glyph.
7. The idle timer screen has exactly three navigation targets: forest, calendar, settings.
8. Premium-only destinations (forest, full calendar) follow the monetization rules:
   during trial they're accessible; post-trial on free tier, the forest icon is not shown
   and the calendar opens showing only the 10-day window.

---

## Aesthetic Techniques

Three techniques define Atrest's visual craftsmanship.
Each has a specific domain. Using them outside that domain breaks the atmosphere.

### Gradients — The World

Gradients serve the **atmospheric canvas** — they ARE the sky, the earth, the passage of light.

**Where gradients belong:**
- The dusk sky background (the `DuskBackground` view — a living gradient from
  `horizonWarm` at bottom to `duskBase` at top)
- The tree's materialization journey (the color temperature shift from cool grey to earthy tone
  is experienced as a gradient over time)
- Screen transitions — the atmosphere should feel continuous across navigation,
  never cut or replaced

**Where gradients do NOT belong:**
- Buttons (flat, quiet, low-opacity fills)
- Cards or content containers (flat `surface` color or transparent)
- UI chrome of any kind
- Text or labels

**The rule:** Gradients serve the *world*. Flat colors serve the *interface*.

### Frosted Glass (`.ultraThinMaterial`) — Interface on World

Frosted glass communicates: *I am a layer on top of something living,
not a wall separating you from it.*

**Where frosted glass belongs:**
- The **escape-hatch overlay** during active fast (the 3–4 navigation options)
- **Calendar and Settings** when presented as sheets — the dusk world bleeds through
- **The paywall surface** — a gentle aside, not a hard gate
- **The transition moment** after fast 10 — frosted overlay on the dusk sky
- **The water expansion** on the timer screen — a translucent chip, not an opaque card

**Where frosted glass does NOT belong:**
- The timer screen's primary content (tree, time, milestones — direct, unmediated)
- The forest canvas (the user is IN the world, not looking through glass at it)
- Any persistent UI element (glass is for moments and overlays, not for permanent surfaces)

**The rule:** Glass is for **interface-on-world**. The world itself is never behind glass.

### Custom SVG Icons — The Experience Layer

Stock SF Symbols make apps feel like apps. Atrest must feel like a place.

**Where custom SVG icons are required:**
- The **3 navigation glyphs** (forest tree, calendar dots, settings gear/stone) — must feel
  like they belong to Atrest's visual world, not to iOS
- The **escape-hatch Atrest glyph** (tree+star mark) — the app's identity mark
- The **water drop indicator** — organic, slightly imperfect, not `drop.fill`
- The **timer action element** — if a glyph is used instead of or alongside text for
  start/stop, it must be custom
- Any decorative element visible during the core experience (fasting, forest)

**Where SF Symbols are acceptable:**
- Export/import icons in Settings
- The back chevron in navigation stacks
- Legal/subscription links
- File picker and system sheets
- Accessibility-only indicators not visible in the primary experience

**The rule:** If the user sees it during the core experience (fasting, forest, transition),
it's custom. If it's infrastructure (file picker, system sheet), system icons are fine.

### The Interplay

The three techniques work together to create depth:

```
[gradient sky — the world]
    ↑ behind
[frosted glass — overlays, sheets, asides]
    ↑ on top of
[custom SVG glyphs — navigation, identity, interaction]
```

This layering produces the sense that Atrest is a *place* with depth,
not a *screen* with widgets.

---

## Screen-by-Screen Specifications

### Timer Screen (Home)

**Hierarchy of attention:** The passage of time — expressed through the elapsed counter,
the materializing tree (premium/trial), and the biological companion text.

**Layout direction:** Centered, vertical. NOT a VStack of left-aligned labels.
The tree occupies the middle-to-lower portion of the screen. Time and milestones
float above it. The action button sits at the bottom.

**During active fast (premium/trial):**
- `DuskBackground` gradient, full-bleed behind everything
- Tree materializing in the lower center (see `04-tree-forest.md` for materialization spec)
- Elapsed time — large, centered, unhurried numerals (not "12.5 hours" — use "12h 30m" format)
- Current biological milestone companion text — one or two lines, centered below time
- Water drop indicator — bottom area, small, tappable
- Escape-hatch glyph — top-left, 30% opacity
- Start/stop action — bottom, low-opacity pill, text label

**During active fast (free tier, post-trial):**
- Same layout, same atmosphere, same milestones and biological text
- No tree. The dusk sky is the backdrop. The screen is quieter but still beautiful.
- Water drop indicator, escape-hatch glyph, action button — all same as premium.

**During idle state:**
- Resting content: a brief line acknowledging readiness ("When you're ready" or similar)
- The 3 floating navigation icons at the bottom
- The dusk background, still atmospheric
- No tree visible (nothing is materializing)
- The start action — bottom, accessible

### Forest Screen (Premium Only)

**Hierarchy of attention:** The forest itself — the accumulated quiet.

As specified in `04-tree-forest.md`: depth-layered free-positioned scrollable canvas,
perpetual dusk sky, parallax star layer, trees at three depth layers.

**Navigation:** The 3 floating icons persist at the bottom (forest glyph at higher opacity
to indicate current location). Back-swipe returns to timer.

**Post-trial free tier:** The forest is not accessible. The forest navigation icon is not shown.
The user does not see a locked or empty forest — the concept simply isn't part of their nav.

### Calendar Screen

**Hierarchy of attention:** Time made visible — a spatial month view, not a list.

**Visual treatment:**
- Presented as a frosted-glass sheet over the dusk background
- The calendar is a **month grid** — standard 7-column layout
- Days with completed fasts show a **small earth-toned dot** (the tree's tone color,
  from the earth palette, matched to that session's assigned tone)
- Days with incomplete fasts (≥70%) show a **small grey dot**
- Days without fasts show nothing — no empty-state marker
- Tapping a dot reveals a detail overlay: date, duration, milestone reached
- The current month is shown by default. User can swipe between months.

**Free tier (post-trial):**
- The calendar shows the last 10 fasting days only.
  Months that contain no visible fasts (beyond the 10-day window) show as empty grids.
  There is NO "locked" label, no "upgrade to see more," no greyed-out dots for older data.
  The calendar simply shows what it shows.

**Premium:**
- Full history. Every month, every fast, every dot. Scrollable back to the first session.

### Settings Screen

**Hierarchy of attention:** None — this is functional. Make it clean and forgettable.

**Visual treatment:**
- Presented as a frosted-glass sheet over the dusk background
- Content in a scrollable list with section headers in muted earth tone
- Earth palette typography for headers, standard for controls
- No cards, no grouped insets — flat, quiet, spacious

**Contents (in order):**

1. **Fasting** section
   - **Target duration** — picker or stepper. Default: 16 hours.
     Options: 12, 14, 16, 18, 20, 24 hours — or free text input.
     This sets the reference point for tree materialization progress
     and the 70% incomplete-fast threshold.
   - **Note beneath:** "This is a reference, not a goal. Your fast is yours regardless."

2. **Hydration** section
   - **Unit preference** — ml or fl oz. Default: ml.
   - **Quick-add amount** — the default increment when tapping the water button.
     Default: 250ml. Options: 150, 200, 250, 300, 500 — or free text.

3. **Premium** section (visible post-trial, free tier only)
   - **"Go premium"** — a single quiet text line, same styling as other rows.
     Tapping opens the paywall sheet.

4. **Data** section
   - **Export data** — exports all session data as JSON
   - **Import data** — imports from JSON file
   - **Explanatory note:** "Your data is stored only on this device."

5. **Account** section (if premium)
   - **Manage subscription** — deep link to App Store subscription management
   - **Restore purchases** — standard restore flow

6. **Legal** section
   - **Terms of Service** — link
   - **Privacy Policy** — link

### Paywall Screen

**Hierarchy of attention:** The values statement — not the price, not the features.

As specified in `05-monetization-ethics.md`: frosted-glass sheet, tree glyph,
values statement → experiential description → two equal price options → restore → legal.

Not repeated here — the monetization doctrine is the authoritative source.

### Water (Inline Element, Not a Screen)

**During active fast:** A small water drop glyph + today's total appears near the
bottom of the timer screen. Custom SVG drop, organic shape, ~16pt, muted opacity.

**Tap to expand:** An inline frosted-glass chip expands in place (not a sheet):
- Today's total — prominently displayed
- Quick-add button ("+250 ml" or configured amount)
- Small scrollable list of today's entries, each with swipe-to-delete
- Tap outside or tap the drop again to collapse

**During idle state:** The water element is not shown. There's no active fast to
hydrate during, and the idle screen shows navigation instead.

**Free tier:** Water is always available, trial and post-trial. Never paywalled.

---

## The Test

Before any element ships, ask:

> Does this deepen the stillness, or does it break it?

If the answer is uncertain, remove the element.
If the answer is clearly "deepen" — protect it, even if it seems excessive.

Restraint is not sparseness. Restraint is removing everything
that does not serve the experience.
The experience is: *being quietly, beautifully present with time*.
