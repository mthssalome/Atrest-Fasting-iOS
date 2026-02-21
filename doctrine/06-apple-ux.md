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

## The Test

Before any element ships, ask:

> Does this deepen the stillness, or does it break it?

If the answer is uncertain, remove the element.
If the answer is clearly "deepen" — protect it, even if it seems excessive.

Restraint is not sparseness. Restraint is removing everything
that does not serve the experience.
The experience is: *being quietly, beautifully present with time*.
