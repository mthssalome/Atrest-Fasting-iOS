# Session State — Depth Toggle Design

> **Written:** 2026-02-23 | **Updated:** 2026-02-24
> **Purpose:** Seamless continuation document. Feed this to Claude at session start.
> **Role:** Claude is acting as systems thinker, critic, and design partner — not a coding assistant. No implementation unless explicitly requested.

---

## Project Status

- **Repository:** `github.com/mthssalome/Atrest-Fasting-iOS.git`
- **Branch:** main at `18c6793` — clean
- **All 8 doctrine files:** finalized and committed (including `08-depth-layer.md`)
- **Full V1 implementation:** committed (33 files, 1650 insertions, 648 deletions)
- **Copy rewrite + 8 SVG tree assets:** committed
- **Handover docs:** `spec/implementation-handover.md` + `spec/implementation-supplement.md`
- **No TestFlight yet. No real users yet. No App Store listing yet.**

---

## What We Were Working On

Designing the **depth toggle** — the opt-in contemplative layer (Surface 2.5 in the three-surface architecture from `doctrine/07-audience-positioning.md`).

This is the feature that makes Atrest uncopyable: the same app serves two audiences at two depths, user-controlled. No secular app can build it authentically. No devotional Christian app can match the experience quality.

---

## Decisions Locked

### All open questions from 2026-02-23 are now resolved.

### 1. The toggle is a content layer, not a mode switch
Nothing about the app's behavior changes. The fast is the same length. The tree materializes the same way. The forest is the same canvas. What changes is **what the app says to you** at certain moments — a second interpretive lens that sits on top of the same experience and transforms its meaning without altering its mechanics.

### 2. Non-denominational, creation-theology grounding
The depth layer lives in pre-denominational territory: creation, stewardship, rest, patience, gratitude, attentiveness, the body as something entrusted. These are universally Christian without signaling any specific tradition.

### 3. The name is "Vigil"
Section label in settings: **Vigil**. Explanation line: *"Adds Scripture and reflective language throughout your fasting experience."* Vigil describes watchful, attentive presence — loaded with precise Christian meaning (keeping vigil, vigil prayers, "watch and pray") while reading as serious and quiet to non-Christians. Not pretentious, not categorical, not denominational.

### 4. Entitlement: Free forever
The Vigil toggle and all V1 content are free. Gating spiritual depth behind a paywall inverts the product's dignity principle. Future Vigil expansions (seasonal content, expanded rotation, community presence) represent curation work and may live in premium.

### 5. Content weight: present throughout, with restraint
Vigil is NOT limited to two touchpoints. It speaks at: idle state, fast start, all 6 milestone phases, arrival, and forest. It is silent at: incomplete fasts (grace doesn't need narrating) and calendar (data view, Scripture cheapens it). Full architecture in `doctrine/08-depth-layer.md`.

### 6. Scripture presentation: fragments, not quotations
Paraphrased in the app's companion voice. No named translations (ESV/NIV/KJV all carry denominational signals). Long-press reveals book and chapter only (not verse number). 2-second fade. Interaction rewards curiosity with precision, then returns to stillness.

### 7. Register: Level 4 with restraint
Explicitly Christian, Apple-esque, aesthetically elegant. Scripture is presented the way a monastery inscribes it on a wall — you encounter it, it encounters you, nobody mediates. Subtler than Spirit Fast or YouVersion, but unmistakably Christian for anyone who opts in.

---

## Open Questions (resolved 2026-02-24)

All three open questions from the previous session have been resolved:
- **A. Entitlement:** Free forever. Decided.
- **B. UI Naming:** "Vigil." Decided.
- **C. Milestone Copy:** All six phases written with companion additions and Scripture fragments. See `doctrine/08-depth-layer.md`.

### Remaining work

1. **Implementation:** Hand `spec/vigil-implementation-handover.md` to a coding AI instance. It has everything needed: module map, phase-by-phase instructions, exact file modifications, new file specs, test specs, and a completion checklist.
2. **Expand idle fragments** from 10 to 30 for full monthly rotation (V1.1).
3. **Future Vigil expansions:** seasonal awareness (Lent, Advent), community presence number, curated arrival prompt expansion. All designed later.
4. **All other pending items** from prior sessions: TestFlight, App Store listing, custom SVG nav icons, visual refinement, marketing strategy brief.

---

## The Gemini Exchange (Context for Continuity)

Two rounds of Gemini advice were critiqued in this session:

### Round 1: "Stop being non-threatening, go explicitly Christian"
**Verdict: structurally wrong.** Gemini presented a false binary (explicit Christian vs. invisible secular). The toggle resolves this natively. Going explicitly Christian trades a Calm-sized opportunity for a YouVersion-adjacent niche. The revenue ceiling of "Christian fasting app" is dramatically lower than "ethical premium fasting companion that resonates with people of faith."

Other wrong elements: adversarial comparison marketing ("Zero vs. Atrest" landing page — premium products don't punch), gamified referral program (violates doctrine), onboarding question ("How would a more disciplined version of you serve your community?" — evaluative, goal-oriented, doctrine-violating), premature GTM for a product that doesn't have TestFlight users.

**One good idea worth keeping:** Lenten timing as a launch window (not a campaign, but a calendar awareness for when to have the app ready).

### Round 2: Gemini acknowledged the toggle strategy wins
**Structural analysis improved significantly.** Three correct insights:
1. Dual-graph word-of-mouth — same app travels through secular and Christian social networks
2. Discovery moment psychology — customer (downloaded for quality) → lifer (found depth layer that speaks to convictions)
3. V1 scoping to milestone language is the right call

**Still wrong:**
- Growth-hack framing throughout ("Trojan Horse," "weaponize," "secret toggle," "VIP key to a hidden room") — translates contemplative product design into manipulative vocabulary
- Milestone copy examples were preachy, instructional, and sermonizing — violated posture doctrine
- "Attack the dark patterns" adversarial marketing persists — Calm never attacked Headspace, premium products occupy space rather than pick fights

**Key line from Claude's critique:** "Gemini now understands the *structure* of the three-surface model. It does not yet understand the *register*."

---

## Touchpoint Map (Reference)

| Moment | Default (Surface 2) | With Depth Active (Surface 2.5) |
|---|---|---|
| Milestone language | Biological companion tone | Biological + contemplative resonance |
| Arrival (tree complete) | Star appears, quiet satisfaction | Star appears + one contemplative line |
| Idle state | "Begin when you're ready" | TBD — could carry reflective quality or stay identical |
| Forest contemplation | Visual beauty, accumulated memory | TBD — future expansion |
| Incomplete fast | Grey starless tree, no penalty | Identical — grace is already embedded |
| Seasonal awareness | None | Future expansion (not V1) |

---

## What Comes Next

1. **Resolve open questions A and B** (entitlement, naming)
2. **Write all six milestone depth variants** (matching the register established above)
3. **Write the arrival line** (or 2-3 candidates to evaluate)
4. **Write the settings UI copy** — the toggle itself, its explanation line, its placement in the settings hierarchy
5. **Decide whether this gets its own doctrine file** (`doctrine/08-depth-layer.md`) or updates `07-audience-positioning.md`
6. **If the user wants implementation:** spec the data model (UserDefaults key, string selection logic, Localizable.strings structure for dual-copy)

---

## How to Resume

Paste this file or point to `spec/session-state.md` and say: **"Continue from session state."**

Remind Claude of its role:
> You are acting as a systems thinker, critic, and design partner. Not a coding assistant. No implementation unless explicitly asked. Think at the architectural, philosophical, and lifecycle level. Be adversarial when necessary.

Then state what you want to work on — likely starting from the open questions above.
