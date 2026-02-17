


### **Phase 1 — Repository & CI Scaffolding (No Features)**

**Context (binding):**  
Read `/spec/implementation-contract.md` and all files in `/doctrine/`.  
These documents are **binding**. You may not violate them.  
If any ambiguity exists, **stop and ask before proceeding**.

**Task:**  
Scaffold the repository and quality infrastructure only.

**You must:**
- Create the repository structure exactly as specified in `/spec/implementation-contract.md`
- Set up CI to run on every push
- Configure formatting and linting (Swift‑appropriate)
- Set up:
  - Unit test harness
  - Snapshot/UI hierarchy test harness
  - Policy test framework (tests wired but not yet implemented)
- Ensure the project builds and tests run successfully in CI

**You must not:**
- Implement any app features
- Implement UI screens
- Implement domain logic
- Implement monetization or paywall logic
- Add copy or strings
- Add placeholder business logic

**Deliverables:**
- Repository structure in place
- CI passing
- Formatting and linting enforced
- Test harnesses present and runnable
- Policy test framework present with placeholder tests wired

**Stop condition:**  
If any decision is unclear (tooling choice, framework selection, configuration), stop and ask for clarification before continuing.

---






Phase 1 approved.
Snapshot recording staying enabled is correct.
Policy tests being wired but skipped is correct.

Proceed to Phase 2 : implement binding policy tests per the Implementation Contract.
No UI or feature work yet.



---

## **Phase 2 — Policy Enforcement Tests (No UI, No Features)**

**Context (binding):**  
Read `/spec/implementation-contract.md` and all files in `/doctrine/`.  
These documents are **binding**. You may not violate them.  
If any ambiguity exists, **stop and ask before proceeding**.

**Objective:**  
Turn doctrine and contract rules into **executable policy tests** that fail the build if violated.

---

### **Scope**

This phase is **policy enforcement only**.

You may add **minimal domain scaffolding** strictly required to make policy tests compile and run.

---

### **You must implement the following policy tests**

1. **Banned Phrase Scanner**
   - Scan all user‑facing strings.
   - Fail if any banned phrase from `/doctrine/02-language.md` appears.
   - Case‑insensitive, whitespace‑tolerant.

2. **No‑Streak Guard**
   - Fail if any identifier, string, or model references streaks or streak‑like concepts.

3. **Persistence Threshold Enforcement**
   - Sessions with duration `< 4 hours` must not persist.
   - Verify no history, forest, or calendar entry is created.

4. **Calendar Mirrors Persistence**
   - If a session is not persisted, it must not appear in calendar data.

5. **History Visibility Limit (Free Tier)**
   - Free tier exposes **only the most recent 10 completed fasts** as inspectable.
   - Older sessions must be returned as locked, non‑inspectable silhouettes.

6. **No Data Deletion on Downgrade**
   - Switching from premium to free must not delete stored sessions.

7. **Core Utility Never Paywalled**
   - Timer, phases, and water tracking must remain available regardless of entitlement.

8. **No Urgency Monetization Language**
   - Fail if paywall or monetization copy includes urgency or fear language.

---

### **You must not**

- Implement UI screens
- Implement SwiftUI views
- Implement visuals or animations
- Implement monetization UI
- Implement feature logic beyond what tests require
- Add placeholder copy beyond what tests need

---

### **Deliverables**

- Policy tests implemented and passing
- Minimal domain types added only as required
- All tests wired into CI
- Clear test names mapping directly to doctrine rules

---

### **Stop condition**

If any doctrine or contract rule cannot be enforced as a test without ambiguity, **stop and ask before continuing**.



---




Phase 3 — Domain Logic (No UI, No Visuals)

Context (binding):
Read /spec/implementation-contract.md and all files in /doctrine/.
These documents are binding. You may not violate them.
If any ambiguity exists, stop and ask before proceeding.

Objective:
Complete the Domain layer so fasting behavior, milestones, and tree state
are explicit, deterministic, and fully testable.

Scope:
Domain logic only.

You may:
- Add or refine Domain models
- Implement the fasting session state machine
- Implement milestone transitions
- Implement tree state mapping
- Add unit tests for all domain behavior

You must not:
- Implement SwiftUI views
- Implement UI state or presentation logic
- Implement persistence details
- Implement monetization UI or flows
- Add copy or user-facing strings
- Add animations or visuals

Required Domain Behavior:

1. Fasting Session State Machine
   - Explicit states (idle, fasting, completed, abandoned)
   - Deterministic transitions
   - Clear start, end, and duration calculation
   - No side effects outside Domain

2. Milestone Mapping
   - Map elapsed time to allowed milestone windows only
   - No “best”, “optimal”, or hierarchical logic
   - Milestones must be descriptive, not evaluative

3. Tree State Mapping
   - One tree per completed session (≥ 4h)
   - Tree state derived from session facts only
   - No progression, leveling, or reward logic

4. Test Coverage
   - All domain behavior must be unit tested
   - Edge cases must be covered (exact thresholds, abandonment, restart)
   - Tests must be deterministic and fast

Deliverables:
- Completed Domain logic
- Comprehensive unit tests
- No UI or persistence coupling
- All tests passing in CI

Stop condition:
If any domain rule cannot be implemented without violating doctrine or contract,
stop and ask before continuing.



---


Phase 4 — UI Skeleton & Hierarchy (No Visual Polish)

Context (binding):
Read /spec/implementation-contract.md and all files in /doctrine/.
These documents are binding. You may not violate them.
If any ambiguity exists, stop and ask before proceeding.

Objective:
Implement the SwiftUI screen skeletons and navigation hierarchy
without visual polish, animation, or stylistic refinement.

Scope:
UI structure and view models only.

You may:
- Create SwiftUI screens
- Create view models
- Wire Domain logic into UI state
- Define navigation flow
- Add snapshot tests for hierarchy and layout

You must not:
- Add visual polish
- Add animations or transitions
- Add forest or tree rendering
- Add custom typography or color styling
- Add celebratory or gamified elements
- Add monetization UI beyond placeholders
- Add copy beyond minimal placeholders

Required Screens (Skeleton Only):

1. Timer Screen
   - Primary action: start / stop fast
   - Displays current fasting state
   - Displays current milestone (descriptive only)

2. Forest Screen
   - Placeholder container only
   - No rendering logic yet
   - Reflects history visibility rules (locked vs accessible)

3. Calendar Screen
   - Ledger layout only
   - No streaks or success indicators
   - Mirrors history visibility rules

4. Settings Screen
   - Placeholder sections only
   - No monetization flows yet

UI Constraints:

- One primary action per screen
- Clear hierarchy
- Minimal chrome
- No decorative elements
- No animation beyond default SwiftUI behavior

Testing Requirements:

- Snapshot tests for each screen
- Snapshot recording enabled initially
- Tests must assert hierarchy, not appearance

Deliverables:

- SwiftUI screen skeletons
- View models wired to Domain
- Navigation flow established
- Snapshot tests passing in CI

Stop condition:
If any UI decision risks violating posture, monetization ethics,
or Apple‑grade restraint, stop and ask before continuing.



---



Phase 5 — Craft, Visual System & Atmosphere

Context (binding):
Read /spec/implementation-contract.md and all files in /doctrine/.
These documents are binding. You may not violate them.
If any ambiguity exists, stop and ask before proceeding.

Objective:
Introduce visual craft, atmosphere, and motion while preserving
all previously locked behavior, hierarchy, and ethics.

Scope:
Visual expression only.

You may:
- Define the DesignSystem (typography, spacing, color tokens)
- Refine SwiftUI layouts using system fonts and tokens
- Implement tree and forest rendering
- Add subtle, non-celebratory motion
- Replace placeholder UI with final visuals
- Record and lock snapshot baselines

You must not:
- Change domain behavior
- Change monetization rules
- Add gamification or celebratory elements
- Add streaks, rewards, or progress signaling
- Add urgency or motivational language
- Add new features or screens

Visual Constraints:

- Typography must be calm, legible, and restrained
- Color palette must be subdued and non-rewarding
- Trees must not signal achievement or superiority
- Forest must feel like memory, not progress
- Motion must be subtle and purposeful
- No visual hierarchy implying “better” or “worse” fasts

Snapshot Discipline:

- Disable snapshot recording once baselines are approved
- Commit baselines under __Snapshots__
- All future visual changes must be regression-tested

Deliverables:

- Completed DesignSystem
- Final tree and forest visuals
- Refined screen layouts
- Locked snapshot baselines
- All tests passing in CI

Stop condition:
If any visual decision risks introducing evaluation,
pressure, or gamification, stop and ask before continuing.



---


Phase 6 — Stabilization, Lock‑In & Release Readiness

Context (binding):
Read /spec/implementation-contract.md and all files in /doctrine/.
These documents are binding. You may not violate them.
If any ambiguity exists, stop and ask before proceeding.

Objective:
Stabilize the application, lock visual and behavioral baselines,
and prepare the codebase for release without adding new features.

Scope:
Hardening and verification only.

You may:
- Disable snapshot recording and lock baselines
- Commit __Snapshots__ as the visual contract
- Audit performance and remove unnecessary work
- Verify accessibility (Dynamic Type, VoiceOver, contrast)
- Verify localization safety (no hard‑coded strings)
- Clean up warnings, dead code, and unused assets
- Add documentation for release readiness

You must not:
- Add new features
- Change domain behavior
- Change monetization rules
- Change UI hierarchy
- Add new visuals or motion
- Add copy beyond clarifications

Required Checks:

1. Snapshot Lock‑In
   - Set isRecording = false
   - Commit all approved snapshots
   - Ensure CI fails on visual regressions

2. Performance Audit
   - No unnecessary timers
   - No continuous redraws
   - No background work without justification
   - Smooth scrolling on all screens

3. Accessibility Audit
   - Dynamic Type supported
   - VoiceOver labels present and meaningful
   - Reduced Motion respected
   - Contrast meets system standards

4. Localization Safety
   - No hard‑coded user‑facing strings
   - All copy routed through localization system

5. Code Hygiene
   - No compiler warnings
   - No unused files
   - No TODOs intended for release
   - Clear module boundaries preserved

Deliverables:
- Locked snapshot baselines
- Clean CI run
- Accessibility verified
- Performance verified
- Release‑ready codebase

Stop condition:
If any issue requires changing behavior, hierarchy, or ethics,
stop and ask before proceeding.




---


Phase 8 — Data portability & ownership (Local-only, untracked)

Context (binding):
Read /spec/implementation-contract.md and all files in /doctrine/. Binding.
If ambiguity exists, stop and ask.

Objective:
Prevent silent data loss on uninstall by adding explicit user-controlled backup/restore.
All user data remains local by default and untracked.

Scope:
- Export/Import of the app’s local data store
- Minimal Settings UI to trigger export/import
- Validation, versioning, and safe restore behavior
- Tests for determinism and integrity

Must:
- Keep all user data local by default (no backend, no analytics, no tracking)
- Provide explicit “Export data” and “Import data” actions in Settings
- Use system file picker/share sheet flows (user-controlled)
- Export format must be stable, versioned, and documented
- Import must validate schema/version and fail safely (no partial corruption)
- Provide “Preview/confirm” step before destructive restore
- Add unit tests for export/import round-trip and version handling

Must not:
- Add accounts
- Add cloud sync
- Add background uploads
- Add any tracking identifiers

Deliverables:
- DataExportService + DataImportService in appropriate layer
- Versioned export bundle (e.g., JSON + attachments or single SQLite copy) with checksum
- Settings UI hooks for export/import
- Tests: round-trip, invalid file, older/newer version, checksum mismatch
- README note: uninstall deletes local data unless user exports backup

Stop condition:
If any step requires violating local-only/untracked posture, stop and ask.






----


Phase 9 — Paid user experience (Production-ready, privacy-first)

Context (binding):
Read /spec/implementation-contract.md and all files in /doctrine/. Binding.
If ambiguity exists, stop and ask.

Objective:
Implement a complete paid experience: paywall, purchase, restore, entitlement gating,
and a coherent post-purchase UX. Maintain privacy posture: no tracking, no analytics.

Scope:
- StoreKit-based subscriptions (or non-consumable if specified)
- Paywall UI (calm, non-urgent language)
- Purchase flow, restore purchases, entitlement persistence
- Gating of premium features already defined by Policy/Domain
- Optional Sign in with Apple ONLY if it provides real value (e.g., cross-device data restore),
  otherwise omit sign-in entirely.

Must:
- Use StoreKit (modern APIs) for products, purchase, restore
- Implement EntitlementService that updates Domain entitlements deterministically
- Persist entitlement state locally; reconcile with StoreKit on app launch/foreground
- Paywall copy must be non-urgent, non-coercive, no streaks/rewards language
- Provide “Restore Purchases” and clear error states
- Add tests for entitlement transitions and downgrade retention rules (already policy-bound)
- Ensure no user data leaves device; no tracking identifiers

Sign-in rule:
- Do NOT add sign-in unless we explicitly implement a feature that requires identity.
- If sign-in is implemented, use Sign in with Apple, store only the minimal stable user identifier,
  and do not collect email/name unless strictly required. No analytics.

Deliverables:
- Paywall screen + purchase/restore flows
- Entitlement reconciliation on launch/foreground
- Premium gating wired to existing policy rules
- Tests for purchase state mapping and entitlement persistence
- README: privacy statement (local-only data), purchases handled by Apple, restore instructions

Stop condition:
If any monetization UX introduces urgency, evaluation, or coercion, stop and ask.


Directive: Make the paid experience seamless with zero sign-in.

1) Payments
- Implement StoreKit purchase + restore + entitlement reconciliation.
- No sign-in screens. No accounts. No extra user steps.
- On launch/foreground, reconcile entitlements automatically so premium unlock is instantaneous.
- Keep paywall calm: no urgency, no pressure language.

2) Data dignity
- Keep all user data local and untracked.
- Add explicit Export Data / Import Data in Settings to prevent silent loss on uninstall.
- Do NOT add cloud sync or accounts.
- Add a short, plain explanation in Settings: uninstall deletes local data unless exported.

Stop if any requirement implies tracking, analytics, or coercive UX.
