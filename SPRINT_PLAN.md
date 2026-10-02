# Development plan

Priority: expand job-source coverage first, then improve extraction and matching.
UI polish, user quotas, paid tiers and billing come last. Each sprint is delivered
in small working slices, with tests and a clean local commit after each slice.

## Completed foundation

| Slice | Current state |
|---|---|
| App and login | React app, email/password and email-link login work. |
| Private preferences | Save/reload and account isolation verified; user confirmed browser persistence. |
| First source | Greenhouse adapter collects Razorpay only; last verified run returned 21 jobs. |
| Job browsing | Job cards and employer application links work; user confirmed the page. |
| Basic matching | Saved role/location comparisons and Any choices work. Unknown-salary and eligibility policies are enforced. |
| Additional preferences | Experience and skills are saved but not compared yet. Salary amount, employment type and work mode are also unverified. |

## Phase 1 — Greenhouse: expand from Razorpay to all companies

The target is all companies publishing jobs through Greenhouse, not a permanent
shortlist of selected employers. Discovery and coverage accounting are part of
the work: do not call coverage complete just because every known board was fetched.

| Sprint | Build | Done when |
|---|---|---|
| 3A — Discover company boards | Find and validate employer board identifiers and career-page evidence. Maintain a registry with company, platform, board identifier, discovery source, verification date and status. Check whether a complete company inventory is available. | A reproducible discovery process and registry exist; valid, invalid, duplicate and inaccessible candidates are distinguished. The total company universe is recorded as unknown unless verified. |
| 3B — Collect across companies | Extend the current workflow to process the registry. Start with a small validation batch, then expand through all discovered valid boards. Isolate failures, handle retries/rate limits, and preserve source identity and raw evidence. | Every discovered board has a collection outcome. Repeated runs do not duplicate postings; one board's failure does not stop others or close their jobs. Different companies can share a source job ID without collision. |
| 3C — Keep coverage current | Add recurring discovery, scheduled collection with a scoped worker login, source health, freshness tracking and resumable runs. Add pagination/batching so storage/API defaults do not silently truncate collection or browser results. | New boards can be added without code changes; expired/renamed boards are tracked; scheduled runs recover from failure. Coverage reports list discovered, validated, collected, failed and stale boards, with outstanding gaps. |

Phase 1 milestone: the Greenhouse discovery-to-collection pipeline works across
all currently discovered accessible boards, and every known gap is visible.
Literal "all companies" remains an ongoing coverage goal unless a complete,
current inventory can be established. Continue discovery after this milestone;
do not block the next phase indefinitely on an unknowable total.

## Phase 2 — Expand beyond Greenhouse to other job sources and their companies

The target is broad company coverage on each added platform, not one sample
company per platform. Platform selection and order remain open until researched.
An integration is not considered ready merely because one endpoint responds.

| Sprint | Build | Done when |
|---|---|---|
| 4A — Evaluate other sources | Inventory candidate recruiting platforms, job boards and employer career-page sources. Check available access methods, company discovery, field coverage, pagination, update behavior and any credentials or costs required. | Each candidate has an evidence-backed capability assessment and go/defer decision. Selected platforms and their order are recorded in product rules; unsupported access is an explicit gap. |
| 4B — Add one platform adapter at a time | Implement and test each selected adapter against a common job format. Preserve original fields, source IDs, timestamps and missing-value information. Add a source-specific profile-field comparison document. | The adapter handles real samples, empty/partial responses, pagination and failures. Relevant collection/access tests pass before expanding its registry. |
| 4C — Expand each platform to all company boards | Repeat the discovery, validation, collection and recurring-update workflow for every selected platform. Reuse registry, health and scheduling infrastructure. | Every discovered company board has a tracked outcome; remaining coverage gaps are explicit. Expansion is repeatable and does not require hardcoded per-company logic. |
| 4D — Unify results across sources | Handle the same job advertised through multiple sources, preserving provenance and a preferred direct application link. Keep distinct jobs separate and distinguish source closure from closure of the underlying opportunity. | Verified duplicate examples are grouped without merging unrelated jobs. A failed or closed source does not erase a still-valid posting from another source. Results remain complete and usable as volume grows. |

Repeat Phase 2 for additional platforms. Report coverage per platform, including
unknown totals; do not claim every job site or every company is supported without
evidence. Geographic or role preferences filter results, not the intended scope
of company discovery.

## Later phases — accuracy, useful actions and delivery

| Sprint | Build | Done when |
|---|---|---|
| 5 — Comparable job facts | Extract explicit experience, required/preferred skills, salary/currency/period, work mode and employment type. Resolve location conflicts; keep evidence and confidence. Clearly label inactive filters in the meantime. | Each active profile filter compares real, compatible facts; missing values remain unknown. Source-specific tests cover conflicting and ambiguous evidence. |
| 6 — Matching quality and shortlist | Improve role/location aliases, hard constraints and explainable ranking; add save/dismiss/applied actions. Evaluate against reviewed job samples. | Relevant and unsuitable cases behave as expected; no invented match claims; private actions persist and remain isolated by account. |
| 7 — Notifications and pilot reliability | Add consent, verified destinations, outbox, scheduling, freshness checks, deduplication, pause and recovery. | Only eligible current undelivered jobs are sent; consent and pause stop queued sends; delivery can recover without duplicates. |
| 8 — UI polish and paid features | Improve presentation after core flows work; then design user quotas, entitlements and billing. | Functional and quality checks pass first; any paid limits and business values are explicitly agreed and stored in product rules. |

## Checks throughout expansion

- Keep browser access read-only for jobs; isolate private profiles and operator data.
- Partial/failed collection must never close missing postings.
- Preserve original source evidence; never turn unknown salary or eligibility into a confirmed fact.
- Operational timeouts, retry policies and request pacing are reliability controls,
  not user-plan quotas. Proposed values belong in config/product-rules.json.
- Maintain source/filter coverage documentation as each adapter is added.
- Run the build and relevant tests before each development commit; record any
  unverified browser or hosted behavior.

Current verification baseline: eight frontend tests and build pass; hosted tests
cover profile isolation, collection lifecycle, job-card access and basic matching.
The latest new preference controls still need browser verification. Security
advisors reported disabled leaked-password protection in Auth; no source-table
or matching access findings were reported in the last checks.

**Next development slice: Sprint 3A — Greenhouse company-board discovery and registry.**
This plan changes priorities; it does not mean new companies or platforms have
already been connected. The configured source remains Razorpay until implemented.
