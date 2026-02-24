# Depth Layer Doctrine — Vigil

## What Vigil Is

Vigil is an opt-in content layer that adds Scripture and reflective language
throughout the fasting experience. It is not a mode. It is not a theme.
It is a second interpretive lens placed over the same product —
changing what the app says at certain moments,
without changing anything about how the app behaves.

The fast is the same length. The tree materializes the same way.
The forest is the same canvas. The mechanics are untouched.

What changes is meaning — offered, never imposed.

---

## Theological Ground

Vigil lives in pre-denominational territory.
Its language draws from creation theology, stewardship, stillness,
attentiveness, and the body as something entrusted.

These concepts are shared across every major Christian tradition
before any of them diverge on anything else.

### What Vigil uses
- Creation theology: the body as gift, food as provision, time as given
- Stewardship: tending what was received, drawing from it carefully
- Stillness: the contemplative posture, being present rather than striving
- Attentiveness: noticing what surfaces, listening rather than explaining
- Scripture: fragments rendered in the app's own voice, not quoted from named translations

### What Vigil avoids
- Named Bible translations (ESV, NIV, KJV, NRSV — all carry denominational signals)
- Sacramental language (divides Catholic/Orthodox from Protestant)
- Liturgical assumptions (not everyone observes Lent; never assumed, only offered in future)
- Prosperity or achievement framing (violates posture doctrine; also charismatic connotation)
- Marian or saints references (Catholicism-specific, unnecessary for this product)
- Commentary or interpretation of any kind (the app places Scripture; it never explains it)

---

## Scripture Presentation

Scripture is presented the way a monastery inscribes it on a wall.
You encounter it. It encounters you. Nobody mediates.

### The aesthetic principle

Massive white space. Perfect typography. One line.
The confidence to let the content be the design
without decorating or explaining it.

This is Atrest's moat against both Spirit Fast (which over-explains)
and YouVersion (which over-references).
Atrest trusts the user with the text.

### Fragment, not quotation

Scripture appears as paraphrased fragments rendered in the app's companion voice.
Not direct quotations from any named translation.

The idea is canonical. The exact words are the app's.

This avoids denominational signaling and creates a participatory quality:
the user's mind completes the fragment. That completion —
the user bringing their own faith to the text — is more powerful
than the full verse because it is an act of recognition, not consumption.

### The long-press reveal

If a user long-presses on a Scripture fragment,
a small, elegant subtitle appears for 2 seconds: the book and chapter only.

> *Be still, and know.*
> [long-press] → Psalm 46

Book and chapter, not book-chapter-verse.
Verse numbers are a study-Bible affordance.
Book and chapter is a location — it tells you where you are in the tradition
without turning the moment into a reference lookup.

For fragments drawn from a broader passage or theme,
the long-press shows the book only:

> *Morning by morning, new mercies.*
> [long-press] → Lamentations 3

This interaction rewards curiosity with precision, then returns to stillness.

---

## Visual Specification

Every visual decision in the Vigil layer must meet the same standard
as the premium experience it lives within. Scripture is not a feature
bolted onto the aesthetic — it is atmosphere that deepens the atmosphere.

The test from `06-apple-ux.md` applies without exception:

> Does this deepen the stillness, or does it break it?

### The Star Register

Stars in the Atrest design system occupy their own visual register:
neither sky (gradient) nor earth (tree tones). A star is near-white light
(`#F0EDE6`) with a soft radial glow. It belongs to a third layer.

**Scripture shares the star register.**

Not the same size, not the same glow — but the same color family,
the same sense of belonging to a layer that is neither ground
nor atmosphere. Stars and Scripture are both quiet points of luminance
in a dark, earthy world — lights that appeared because something
was completed, or given, or held.

This creates a subtle visual kinship between stars in the forest sky
and verse fragments on the timer. The user never thinks about this
consciously. They feel it.

### Typography

Scripture fragments are typeset as their own register —
distinct from both companion text and UI labels.
They are not body copy. They are not headings.
They are inscriptions: the typographic equivalent
of words carved slowly into stone.

- **Weight:** lighter than companion text.
  If companion is `regular`, Scripture is `light` or `ultraLight`.
- **Size:** slightly smaller than companion text.
  Scripture is not competing for attention; it is present beneath it.
- **Tracking (letter-spacing):** wider than companion text.
  Each letter has room to breathe.
  This is what makes inscription feel different from prose.
- **Color:** star-register tone — `#F0EDE6` at ~60% opacity.
  Not the same white/near-white as body text.
  Scripture lives in the same visual register as stars:
  its own light, neither sky nor earth.
- **Alignment:** centered. Always.
  Scripture is not left-aligned prose.
  It sits in the center of its space like text on a monument.
- **Line height:** extremely generous.
  If the fragment is two lines, the gap between them
  should feel deliberate, not automatic.

### Hierarchy of Attention

The aesthetic doctrine's hardest rule:

> Each screen has one thing that the eye is meant to rest on.
> One. Everything else recedes.

**Scripture fragments are subordinate to the primary attention object
on every screen.** They never compete with the tree, the elapsed time,
or the forest. They are present the way a watermark is present —
noticeable when you look, invisible when you don't.

The eye should be able to rest on the primary object for minutes
without Scripture pulling focus.

Specific placement:

- **Timer screen:** milestone Scripture sits *below* the companion text,
  after a generous spacer (~20pt). It is the last thing in the content
  stack, closest to the bottom. Not demanding, not calling. There.
- **Forest screen:** "Consider how they grow" is anchored to the bottom
  edge of the viewport — not scrolling with the trees. Small. Muted.
  The inscription on the frame of the painting, not in the painting.
- **Idle screen:** the daily fragment sits below "Begin when you're ready"
  — a subtitle to the day, not a headline. Approximately 24–32pt
  of space between prompt and Scripture. Close enough to feel related,
  far enough to be clearly a different voice.

### Surface Treatment

The aesthetic doctrine defines three layers:

> Gradients = the world. Frosted glass = interface on world.
> Custom SVG = the experience layer.

**Scripture renders directly over the gradient, with no background surface.**

No chips. No cards. No frosted backing. The text floats in the dusk
the same way the elapsed time floats in the dusk.
It is part of the world, not on top of it.

If Scripture were placed on a frosted-glass chip, it would become UI —
a feature, a component. Floating in the air of the dusk sky,
it becomes atmosphere — part of the place.

Inscription on the wall of the room, not a plaque hung on the wall.

### Motion Choreography

All animations follow the motion doctrine: 300–600ms, organic easing,
never celebratory, never urgent.

**Fast-start line** ("You have set this time apart."):
- Fade in: 600ms, ease-out (arrives gently, like breath)
- Hold: 2.5 seconds
- Fade out: 800ms, ease-in (leaves more slowly than it arrived)
- Total presence: ~4 seconds
- The user catches it, or doesn't. It never repeats for that fast.

**Milestone Scripture appearance** (on phase transition):
- The companion text updates immediately as it does now.
  The Scripture fragment fades in 400ms *after* the companion text
  settles — a beat of separation. Two things arriving at different
  times, not a block of text that swaps in at once.
- Ease curve: ease-out (the fragment arrives; it does not snap).

**Long-press citation reveal:**
- Appear: 300ms fade-in (responsive — the user asked for this)
- Hold: 2 seconds
- Fade out: 500ms ease-in
- Position: directly below the Scripture fragment, center-aligned
- Typography: caption-weight, wider tracking than the Scripture itself.
  Same star-register color at ~40% opacity.
  Book and chapter reads as a quiet whisper below the inscription.

**Arrival Scripture:**
- Appears 800ms after the star has fully faded in.
  The star is first. Always. The star is the product's signature moment.
  Scripture follows — a companion to the star, not a replacement for it.
- Fade in: 600ms ease-out.
- Remains for as long as the user stays on the completion screen.
  No fade-out. It is there until they leave.

**Forest inscription** ("Consider how they grow."):
- Present on screen entry. No animation. It is always there,
  the way an inscription on a wall is always there.
  You notice it when you notice it.

### The Idle Screen Composition

With Vigil active, the idle screen has a three-layer vertical composition:

```
              [resting prompt — centered, mid-screen]

                         ~24–32pt spacer

     [daily Scripture — centered, star-register color, lighter weight]




              [forest]    [calendar]    [settings]
              40% opacity floating navigation icons
```

The Scripture sits in the gravitational field of the prompt
but is clearly a different voice — a different weight, a different color,
a different tracking width. Two layers of the same quietness.

### What Vigil Must Never Do Visually

- Add a new color to the palette. Scripture uses what exists (star register).
- Add a background surface where none exists. No cards, no chips, no badges.
- Increase the information density of any screen. If adding Scripture
  makes a screen feel heavier, the spacing is wrong.
- Animate anything that the default layer does not animate.
  Vigil adds *content* to existing motion moments; it does not create new motion.
- Alter the tree, the star, the forest, the dusk gradient, or any element
  of the core visual experience. Vigil is words. The world is unchanged.

---

## Touchpoint Architecture

Vigil speaks at specific moments. Not all of them. Not constantly.
The restraint is architectural — silence between touchpoints
is what gives the words their weight.

### Idle state (no active fast)

A single rotating Scripture fragment beneath "Begin when you're ready."
Changed daily, not per visit. The user lives with one line for a whole day.

These fragments are atmospheric, not fasting-specific.
They establish that the app, with Vigil on,
inhabits a devotional stillness even when nothing is happening.

The verse sits below the idle prompt like a contemplative subtitle to the day.

**V1 fragments (10):**

| Fragment | Long-press |
|---|---|
| *The earth is full of your steadfast love.* | Psalm 119 |
| *Morning by morning, new mercies.* | Lamentations 3 |
| *The heavens declare.* | Psalm 19 |
| *He leads me beside still waters.* | Psalm 23 |
| *In him all things hold together.* | Colossians 1 |
| *Great is your faithfulness.* | Lamentations 3 |
| *Your hands have made and fashioned me.* | Psalm 119 |
| *Even the darkness is not dark to you.* | Psalm 139 |
| *In returning and rest you shall be saved.* | Isaiah 30 |
| *Consider the birds of the air.* | Matthew 6 |

Target: 30 fragments for full monthly rotation (V1.1 expansion).

### Fast start

A single companion line appears briefly (3–4 seconds, fades)
as the fast begins:

> *You have set this time apart.*

Not Scripture. Companion voice.
An acknowledgment that what the user is doing is intentional.
It fades. The timer screen returns to its default state.
The moment is marked, not dwelt on.

### Milestones (6 fasting phases)

The biological companion text is fully preserved.
A contemplative addition is woven as a natural extension —
same voice, one more breath. The Scripture fragment sits below
as a separate visual element: lighter weight, generous space above,
like an inscription.

The app never connects the biological and spiritual layers.
It places them side by side and trusts the user.

---

**0–4 hours: Digestion completing**

Default companion:
> Your last meal is still being processed. Nothing has shifted yet.

Vigil companion:
> Your last meal is still being processed. Nothing has shifted yet.
> For now, it is simply a choice — a quiet setting-apart of hours.

Vigil Scripture:
> *This is the day.*
> Long-press: Psalm 118

---

**4–8 hours: Beginning to shift**

Default companion:
> Your body has finished digesting and is beginning to draw on its own reserves.

Vigil companion:
> Your body has finished digesting and is beginning to draw on its own reserves.
> What was received is now being tended — drawn from gently.

Vigil Scripture:
> *I shall not want.*
> Long-press: Psalm 23

---

**8–12 hours: Metabolic transition**

Default companion:
> You may start to feel the fast more here. Your body is shifting between energy sources — a natural and temporary adjustment.

Vigil companion:
> You may start to feel the fast more here. Your body is shifting between energy sources — a natural and temporary adjustment.
> This is often where choosing to remain becomes its own quiet practice.

Vigil Scripture:
> *When you pass through, I will be with you.*
> Long-press: Isaiah 43

---

**12–16 hours: Deeper fasting state**

Default companion:
> Your body has settled into a deeper rhythm, drawing more on stored energy. Some people feel clearer here; others feel the challenge more.

Vigil companion:
> Your body has settled into a deeper rhythm, drawing more on stored energy. Some people feel clearer here; others feel the challenge more.
> Not only the body finds a rhythm — something quieter settles alongside it.

Vigil Scripture:
> *Be still, and know.*
> Long-press: Psalm 46

---

**16–24 hours: Extended fasting**

Default companion:
> You are well into an extended fast. Your body is working with what it has. There is nothing to do but be here.

Vigil companion:
> You are well into an extended fast. Your body is working with what it has. There is nothing to do but be here.
> For thousands of years, fasting this long has been understood as a way of making room.

Vigil Scripture:
> *Not by bread alone.*
> Long-press: Matthew 4

---

**24+ hours: Prolonged fasting**

Default companion:
> This is a long fast. Your body has found its own pace. Be attentive to how you feel.

Vigil companion:
> This is a long fast. Your body has found its own pace. Be attentive to how you feel — and to what else surfaces in the stillness.

Vigil Scripture:
> *Search me, and know my heart.*
> Long-press: Psalm 139

---

### Arrival (fast complete, tree materialized, star appears)

The highest-receptivity moment.
A Scripture fragment sits below the completed tree
for as long as the user remains on the screen.
No animation, no fanfare. Presence.

Rotates per fast, cycling through five fragments:

1. > *In every season, it yields its fruit.*
   > Long-press: Revelation 22

2. > *What was begun in you is being carried to completion.*
   > Long-press: Philippians 1

3. > *To everything, a season.*
   > Long-press: Ecclesiastes 3

4. > *The Lord bless you, and keep you.*
   > Long-press: Numbers 6

5. > *You prepare a table before me.*
   > Long-press: Psalm 23

---

### Forest

One permanent inscription. Not rotating, not changing.
Present every time the user visits their forest:

> *Consider how they grow.*
> Long-press: Luke 12

In the context of a forest of trees grown through fasting,
this accrues meaning over months.
The first time: a nice line.
The fiftieth time, looking at fifty trees: something else entirely.

---

### Incomplete fast

No Scripture. No contemplative addition. Identical to default.

If the depth layer speaks at the moment of an incomplete fast,
it risks implying that God has something to say about failure to finish.
Even a gentle verse here carries the weight of spiritual evaluation.

Silence at this moment is the Christian message.
Grace does not need to be narrated.

---

### Calendar

No change. The calendar is a data view.
Adding Scripture to data cheapens both.

---

## Entitlement

The Vigil toggle and all of its V1 content are free.
Gating spiritual content behind a paywall creates an inversion:
the free Christian user would receive a less meaningful experience
than the free secular user, because the secular user's default is complete
while the Christian user can see a deeper layer they are being denied.

Future Vigil expansions — curated seasonal content,
expanded prompt rotation, community presence —
represent ongoing editorial and curation work.
That work can live in premium.

**The rule:** access to the depth layer is never paywalled.
Access to curated expansions of the depth layer may be.

---

## Settings

The toggle appears in settings as:

> **Vigil**
> *Adds Scripture and reflective language throughout your fasting experience.*

Single toggle. One explanation line. The word "Scripture" is stated directly.
The user who turns this on knows exactly what they are choosing.

The toggle is never promoted within the app.
It is never surfaced during onboarding.
It is discovered in settings by a user who is looking.

---

## Rules

1. Vigil is always opt-in, never default, never promoted within the app.
2. Vigil changes what the app says. It never changes what the app does.
3. Scripture is presented as paraphrased fragments in the app's companion voice, never as direct quotations from named translations.
4. No fragment is accompanied by commentary, interpretation, or explanation. The text is placed. Nothing else is said.
5. The long-press reveal shows book and chapter only, never translation, never verse number.
6. The biological companion text is fully preserved when Vigil is active. The contemplative addition extends it; it does not replace it.
7. No Scripture appears at the moment of an incomplete fast. Silence is the message.
8. No Vigil content may evaluate the user, praise their discipline, or imply that fasting earns spiritual merit.
9. The theological ground is pre-denominational: creation, stewardship, stillness, attentiveness. No content may signal a specific tradition.
10. All Vigil content is free. Spiritual depth is never paywalled.

---

## Content Inventory

| Touchpoint | V1 pieces | Status |
|---|---|---|
| Idle daily fragments | 10 (30 target) | Curated |
| Fast start line | 1 | Written |
| Milestone companion additions | 6 | Written |
| Milestone Scripture fragments | 6 | Curated |
| Arrival rotation | 5 | Curated |
| Forest inscription | 1 | Written |
| Incomplete fast | 0 (intentional) | Decided |
| Calendar | 0 (intentional) | Decided |
| **Total V1** | **29** | |
