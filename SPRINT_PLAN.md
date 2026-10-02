# Development plan

This is the active, compact replacement for the old `docs/09-sprint-plan.md`. Sprints are ordered work slices, not promised dates. Finish the listed check before expanding UI or adding paid features.

| Sprint | Build | Done when |
|---|---|---|
| 0 — Foundation | React app, Supabase client, private profile migration, simple local preview | App builds; preview and email sign-in work; live profile save remains to verify |
| 1 — User preferences (current) | Role, location, work mode, compensation and unknown-field choices; validation; pause setting | A signed-in user can save and reload preferences; another user cannot read or alter them |
| 2 — Job data | Source registry, one relevant employer feed, collection run outcomes, canonical job records | Repeat runs do not duplicate jobs; source failure is visible; partial runs do not close jobs |
| 3 — Matching and shortlist | Hard eligibility checks, ranking, reasons, private shortlist, save/dismiss/applied actions | Different preferences yield explainable lists; unknowns are labelled; actions persist |
| 4 — Delivery | Consent, verified destination, daily schedule, outbox, send-time checks, pause | At most the configured number of current jobs is sent once; pause and revoked consent stop queued sends |
| 5 — Pilot readiness | Access, quality, recovery, cost and usability checks | Critical flows pass with real source samples and test recipients; unresolved risks are recorded |

**Current focus:** implement and verify Sprint 1. Email sign-in worked on the second try; the first failure needs observation if it recurs. The preference schema and local form are in place. Hosted database save/reload, two-identity row-level isolation, ownership reassignment denial, and anonymous access denial passed on 2026-10-02 using the rollback-only `supabase/tests/profile_access.sql` suite. Six local validation tests and the production build pass. Signed-in browser save/refresh remains to verify end to end; database-role tests do not verify Auth token issuance or the browser integration.

Paid alerts, billing, extra channels, auto-apply, and UI expansion follow evidence from the first useful flow. Product values and open decisions live in [product-rules.json](config/product-rules.json).
