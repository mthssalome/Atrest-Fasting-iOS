# Session State — Depth Toggle Design

> **Written:** 2026-02-23
> **Purpose:** Seamless continuation document. Feed this to Claude at session start.
> **Role:** Claude is acting as systems thinker, critic, and design partner — not a coding assistant. No implementation unless explicitly requested.

---

## Project Status

- **Repository:** `github.com/mthssalome/Atrest-Fasting-iOS.git`
- **Branch:** main at `acecc3f` — clean, pushed
- **All 7 doctrine files:** finalized and committed
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

### 1. The toggle is a content layer, not a mode switch
Nothing about the app's behavior changes. The fast is the same length. The tree materializes the same way. The forest is the same canvas. What changes is **what the app says to you** at certain moments — a second interpretive lens that sits on top of the same experience and transforms its meaning without altering its mechanics.

### 2. Non-denominational, creation-theology grounding
The depth layer lives in pre-denominational territory: creation, stewardship, rest, patience, gratitude, attentiveness, the body as something entrusted. These are universally Christian without signaling any specific tradition.

**Avoid:** named Bible translations, sacramental language, liturgical assumptions, prosperity/achievement framing, Marian/saints references. **Use:** creation theology, body-as-gift, quiet practice, threshold language, attentiveness, honoring what was given.

### 3. V1 content weight: lightest possible (two touchpoints only)
- **Touchpoint 1:** Milestone language shifts — alternate copy for each fasting phase when toggle is on
- **Touchpoint 2:** A single contemplative line at the arrival moment (tree completion)
- **Nothing else for V1.** No liturgical calendar, no seasonal awareness, no community presence number. Those are future expansions that will feel like the app growing alongside the user.

### 4. Register: invitation, never instruction
The depth layer suggests proximity to the sacred without explaining it, assigning theological meaning, or commanding the user. It opens a space for meaning-making; it does not deliver meaning.

**The test:** if the line could be read as a sermon, a command, or an explanation of what the user's fast "means," it fails.

### 5. Copy direction established (examples from this session)

**Default milestone (8–12h):**
> "You may start to feel the fast more here. Your body is shifting between energy sources — a natural and temporary adjustment."

**With depth active (8–12h):**
> "You may start to feel the fast more here. The body shifts between sources. Some have called this the threshold — where choosing to be present becomes its own quiet practice."

**Arrival line (depth active):**
> "The fast is complete. What was given has been honoured."

Note: these are directional, not final copy. The register is the binding constraint.

---

## Open Questions (to resolve when session resumes)

### A. Entitlement: Free or Premium?
Claude's recommendation: **milestone language shifts should be free.** Gating spiritual depth behind a paywall is optically wrong — it looks like charging for Scripture. If richer additions come later (curated seasonal content, arrival prompt rotation, community presence), that *curation work* can live in premium.

Counter-argument flagged: making depth free but premium-only for richer additions could create three-tier perception (free-secular, free-Christian-lite, premium-Christian-full) that might feel patronizing.

**User has not yet decided.**

### B. UI Naming: What appears in settings?
Claude's instinct: a section called **"Depth"** with a single quiet toggle and one explanation line — something like *"Adds contemplative language to milestones and completion moments."*

Rejected options and why:
- "Reflections" — suggests journaling, wrong affordance
- "Contemplative mode" — pretentious
- "Faith" — too explicit, collapses the three-surface model
- "Christian content" — violates rule 6 of audience positioning doctrine

The name should be environmental, not categorical. The content signals the tradition; the label doesn't have to.

**User has not yet decided.**

### C. Exact Milestone Copy
All six phases need depth-active variants written. Only one example exists (8–12h). The register is locked; the words are not.

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
