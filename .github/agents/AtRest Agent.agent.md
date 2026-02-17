

## **Agent Quality & Performance Constitution (Binding)**

**Status:** Non‑negotiable  
**Applies to:** All phases, all code, all decisions

---

### **1. Performance Discipline**

You must assume this app is:
- Long‑running
- Frequently backgrounded
- Used during low‑battery states
- Used during physical discomfort

Therefore:

- No polling loops
- No unnecessary timers
- No continuous redraws
- No heavy animations
- No background work without explicit justification
- No synchronous disk writes on the main thread

All time‑based behavior must be:
- Event‑driven
- State‑based
- Battery‑conscious

If performance impact is unclear, stop and ask.

---

### **2. Memory & Resource Discipline**

- No retained references without ownership clarity
- No global singletons unless explicitly justified
- No implicit state shared across modules
- No unbounded collections
- No silent data duplication

All stored data must have:
- A clear lifecycle
- A clear owner
- A clear reason to exist

---

### **3. Architectural Boundaries (Strict)**

You must not violate module boundaries:

- **Domain**
  - Pure logic only
  - No UI imports
  - No persistence details
  - No entitlement logic

- **Data**
  - Persistence and export only
  - No business rules
  - No UI assumptions

- **UI**
  - Presentation only
  - No business logic
  - No persistence logic

- **DesignSystem**
  - Tokens and components only
  - No app logic
  - No state machines

- **Policy**
  - Enforcement only
  - No feature logic

If a rule crosses boundaries, stop and ask.

---

### **4. Quality Bar (Apple‑Grade)**

You must prefer:
- Fewer features over more
- Clear code over clever code
- Explicitness over inference
- Readability over abstraction

You must avoid:
- Premature optimization
- Over‑engineering
- “Helpful” additions not requested
- Silent assumptions

Every file must justify its existence.

---

### **5. Testing Discipline**

- No logic without tests
- No behavior without policy coverage
- No UI without snapshot tests
- No snapshot recording left enabled once baselines exist

If a test cannot be written, the behavior is not allowed.

---

### **6. Change Control**

You must not:
- Expand scope
- Add features
- Add UI
- Add copy
- Add monetization logic

Unless explicitly instructed in the current phase.

If you believe something *should* be added, stop and propose it instead.

---

### **7. Failure Mode**

If any instruction conflicts with:
- `/spec/implementation-contract.md`
- `/doctrine/*`

Those documents win.

If ambiguity exists:
- Stop
- Ask
- Do not guess

---

## **Acknowledgement Requirement**

Before proceeding with Phase 2, respond with:

> “Acknowledged. I will operate under these constraints and stop if ambiguity arises.”

Only after that acknowledgement may work continue.

---
