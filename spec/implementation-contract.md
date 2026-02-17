# Implementation Contract

This document defines the non-negotiable implementation rules for the application.
All code, UI, copy, and behavior must comply with this contract.
If ambiguity arises, implementation must stop and clarification must be requested.

---

## Platform & Stack

- Platform: iOS-only (v1)
- UI Framework: SwiftUI
- Architecture: Modular (Domain / Data / UI / DesignSystem / Policy)
- Quality Bar: CI-gated, tests-first, no feature work without passing policy tests

---

## Core Behavioral Rules

### Fasting Session Persistence

- A fasting session is persisted only if duration ≥ 4 hours.
- Sessions < 4 hours:
  - Are not saved
  - Do not create a tree
  - Do not appear in calendar or history
- Sessions ≥ 4 hours:
  - Are persisted
  - Create exactly one tree
  - Appear in calendar and history

---

## Tree & Forest Semantics

- One tree represents one completed fasting session (≥ 4 hours).
- Trees change by state, not by improvement.
- No visual hierarchy, reward, or superiority is permitted.
- Forest represents memory, not merit.

---

## History Visibility Rules

### Free Tier

- The most recent 10 completed fasting sessions are fully accessible.
- Older sessions:
  - Remain stored
  - Are visually present as atmospheric silhouettes
  - Are not inspectable
  - Do not expose duration, timestamps, or metadata

### Premium Tier

- Full access to all historical sessions
- Full forest visibility
- Full calendar access

---

## Calendar Rules

- Calendar is a factual ledger only.
- No streaks, success/failure indicators, or gap highlighting.
- Calendar mirrors history visibility:
  - Free: entries for most recent 10 sessions
  - Premium: full history

---

## Monetization Rules

### Pricing

- Annual subscription only: $29.99/year
- Lifetime supporter option: $69.99 one-time
- No monthly subscriptions

### Trial Model

- First 10 completed fasts:
  - Full premium access
  - No payment method required
  - No prompts or reminders
- Fast 11:
  - One non-intrusive notice at completion
- Fast 12+:
  - Soft reversion to free tier

### Soft Reversion

- Core utility (timer, phases, water) must remain fully functional
- No data deletion
- No repeated reminders
- No urgency language

---

## UX & Accessibility Constraints

- One primary action per screen
- No gamification artifacts (badges, streaks, achievements)
- Motion must be subtle and non-attention-seeking
- Full Dynamic Type and VoiceOver support
- Reduced Motion respected
- Performance must remain smooth and battery-conscious

---

## Acceptance Gates

A change may be merged only if:

1. All unit tests pass
2. All policy tests pass
3. All snapshot/UI hierarchy tests pass
4. Linting and formatting pass
5. One human review is completed
