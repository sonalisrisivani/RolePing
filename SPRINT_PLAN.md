# Development plan

This is the active, compact replacement for the old `docs/09-sprint-plan.md`. Sprints are ordered work slices, not promised dates. Finish the listed check before expanding UI or adding paid features.

| Sprint | Build | Done when |
|---|---|---|
| 0 — Foundation | React app, Supabase client, private profile migration, simple local preview | App builds; preview and email sign-in work; live profile save remains to verify |
| 1 — User preferences (browser verification pending) | Role, location, work mode, compensation and unknown-field choices; validation; pause setting | A signed-in user can save and reload preferences; another user cannot read or alter them |
| 2 — Job data (first feed verified) | Source registry, one relevant employer feed, collection run outcomes, canonical job records | Repeat runs do not duplicate jobs; source failure is visible; partial runs do not close jobs |
| 3 — Matching and shortlist | Hard eligibility checks, ranking, reasons, private shortlist, save/dismiss/applied actions | Different preferences yield explainable lists; unknowns are labelled; actions persist |
| 4 — Delivery | Consent, verified destination, daily schedule, outbox, send-time checks, pause | At most the configured number of current jobs is sent once; pause and revoked consent stop queued sends |
| 5 — Pilot readiness | Access, quality, recovery, cost and usability checks | Critical flows pass with real source samples and test recipients; unresolved risks are recorded |

**Current progress (2026-10-02):** Sprint 1 database save/reload and two-identity access tests pass. Six preference tests and the production build pass. Signed-in browser save/refresh remains unverified: computer-control permission was denied on this Mac and the browser CLI is unavailable. No UI expansion was added while that check remains open.

Sprint 2's first manual collection slice is implemented and verified. The Python Greenhouse adapter imported 21 Razorpay postings twice, leaving 21 distinct records. Fourteen worker tests and the rollback-only hosted `supabase/tests/collection_access.sql` suite pass, covering repeat imports, retries, partial/failed run safety, source isolation, closure, older responses, reopening, and access boundaries. Supabase security advisors returned no findings. Source selection and operational limits are proposed values in `config/product-rules.json`.

**Next:** complete the signed-in browser check when computer control is available, then build explainable matching and a private shortlist. Scheduling remains deferred until cadence/freshness decisions and a dedicated worker login are in place. Manual collection works via the existing authenticated CLI without new credentials. The optional direct-driver path is installed but has not been tested against a dedicated hosted login. See `worker/README.md` for run commands and limitations.

Paid alerts, billing, extra channels, auto-apply, and UI expansion follow evidence from the first useful flow. Product values and open decisions live in [product-rules.json](config/product-rules.json).
