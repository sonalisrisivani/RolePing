# Development plan

This is the active, compact replacement for the old `docs/09-sprint-plan.md`. Sprints are ordered work slices, not promised dates. Finish the listed check before expanding UI or adding paid features.

| Sprint | Build | Done when |
|---|---|---|
| 0 — Foundation (current) | React app, Supabase client, private profile migration, simple local preview | App builds; preview works; connected sign-in and profile save are verified after project setup |
| 1 — User preferences | Role, location, work mode, compensation and unknown-field choices; validation; pause setting | A signed-in user can save and reload preferences; another user cannot read or alter them |
| 2 — Job data | Source registry, one relevant employer feed, collection run outcomes, canonical job records | Repeat runs do not duplicate jobs; source failure is visible; partial runs do not close jobs |
| 3 — Matching and shortlist | Hard eligibility checks, ranking, reasons, private shortlist, save/dismiss/applied actions | Different preferences yield explainable lists; unknowns are labelled; actions persist |
| 4 — Delivery | Consent, verified destination, daily schedule, outbox, send-time checks, pause | At most the configured number of current jobs is sent once; pause and revoked consent stop queued sends |
| 5 — Pilot readiness | Access, quality, recovery, cost and usability checks | Critical flows pass with real source samples and test recipients; unresolved risks are recorded |

**Current focus:** finish Sprint 0 with a real Supabase project, then implement Sprint 1. I can develop local code, migrations, fixtures, and tests while external setup is pending. I cannot verify hosted authentication or apply a migration to your project until it is connected.

Paid alerts, billing, extra channels, auto-apply, and UI expansion follow evidence from the first useful flow. Product values and open decisions live in [product-rules.json](config/product-rules.json).
