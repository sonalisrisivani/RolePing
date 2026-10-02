# Role Ping — Directory review and sprint plan

Draft · 2 October 2026 · Planning proposal, not a delivery commitment

## Review findings

The repository is ready for implementation planning, not pilot deployment. It contains eight product documents and a historical scraping benchmark, including a reproduction ZIP. There is no application, runnable database migration, worker service, CI configuration, or application test suite. The working tree was clean at review time.

| Finding | Evidence | Planning consequence |
|---|---|---|
| MVP scope and acceptance criteria are documented | [PRD](02-PRD.md), FR-01–FR-14 | Build against these requirements; do not expand into paid features |
| Roadmap has milestones but no executable sprint backlog | [Roadmap](07-roadmap.md), M0–M6 | Add work packages, dependencies, demonstrations, and exit checks |
| Cohort, stack, worker hosting, channel, budget, and owners remain unresolved | [Decision log](08-decisions-and-risks.md) | Resolve these before dependent implementation or provisioning |
| Retrieval evidence is promising but does not establish cohort relevance | [Benchmark](../evidence/job-scraping-benchmark/REPORT.md): 34/45 Python records plausibly fresher-suitable; not personalised eligibility | Validate opportunity supply before investing in the full student interface |
| Data conflicts are observed, not hypothetical | Benchmark salary, remote, title/description, and date discrepancies | Ship provenance, quarantine, and hard filtering with the first pipeline |
| Privacy, delivery, and operations are specified but unimplemented | [Architecture](03-architecture-and-data.md), [delivery](05-experience-and-plans.md) | Reserve explicit work for access tests, send races, deletion, and operator recovery |
| Pilot supply and coverage thresholds are unset | [Validation plan](06-launch-and-validation.md) | Agree numeric gates from cohort evidence; precision alone cannot pass |

This review inspected repository documents, benchmark report/results, and archive inventory. It did not execute archived scripts, rerun scraping, verify external services, or audit a running application.

## Capacity and scope assumptions

- Proposed cadence: two-week sprints, one full-time engineer, founder/product owner available for interviews and decisions, and a named pilot operator. These roles are not assigned yet.
- Plan around eight engineering days per sprint, leaving two days for review, fixes, and integration. Estimates below are provisional engineering days, not measured velocity; re-estimate after Sprint 1.
- Five build sprints precede a four-week pilot. This is a sequencing hypothesis, not a ten-week launch promise. Split work across additional sprints if measured capacity is lower; do not remove release checks to preserve dates.
- One cohort, a narrow role/location set, one preference set per user, one verified delivery channel, and up to five qualifying new jobs per daily digest.
- Existing architecture and email-first recommendations remain provisional. This plan selects no new vendor, framework, price, or paid service.
- Resume tools, auto-apply, billing, faster paid alerts, additional channels, public sharing, mobile apps, and college dashboards stay outside this build.

## Sprint 1 — Prove cohort and source fit (M0)

Goal: establish whether the selected students can receive a useful shortlist and make the implementation decisions concrete.

| ID | Work and accountable role | Estimate | Acceptance / output |
|---|---|---:|---|
| S1-01 | Founder: interview 12–15 students; choose cohort, roles, locations, channel preference; engineer prepares evaluation template | 1 day engineering support | 20 representative profiles prepared with permission or clearly labelled synthetic cases; synthetic cases do not substitute for demand evidence |
| S1-02 | Founder + engineer: resolve stack, hosting, budget cap, operator, unknown-field defaults, retention, and channel decisions | 1 day | Decision log records choices, rationale, owners, and unresolved blockers; no provisional recommendation silently becomes approved |
| S1-03 | Engineer: build employer registry and a repeatable cohort evaluation harness using selected sources | 3 days | Registry records board IDs, relevance, access conditions, run outcome, and sample provenance; fresh evidence goes in a separately dated folder |
| S1-04 | Engineer + founder: adjudicate accepted and rejected jobs, compare baseline coverage, record supply gaps | 3 days | Per-profile top-five precision, unique opportunity counts, zero-match fraction, and reference-set coverage reported; numeric supply/coverage gates agreed before further gate evaluation |

Dependencies: founder supplies cohort access and relevant employer history. Interviews are founder work outside the engineering estimate. If access is delayed, fixture/harness work can proceed but the source-fit gate stays open.

Demo: manually reviewed shortlists for representative profiles, with caveats and rejection reasons.

Exit: selected sources meet the agreed useful-supply gate, or the founder narrows/changes the cohort and repeats validation. Do not advance the full product build merely because scraping returns records.

## Sprint 2 — Build the durable collection pipeline (M1)

Goal: turn validated sources into reproducible, traceable job records.

| ID | Work and accountable role | Estimate | Acceptance / output |
|---|---|---:|---|
| S2-01 | Engineer: scaffold chosen runtime, worker, migrations, configuration examples, and CI | 2 days | Fresh checkout setup works; migrations reproduce the data foundation; secrets stay outside source control; automated checks run |
| S2-02 | Engineer: JobSpy wrapper and one cohort-relevant employer-feed adapter | 2 days | Bounded requests, per-source isolation, completeness tracking, and distinct empty/partial/blocked/timeout/schema outcomes; one failed source preserves healthy results |
| S2-03 | Engineer: canonical records, evidence fields, validation, conservative deduplication, lifecycle | 3 days | Repeated IDs upsert; distinct requisitions remain separate; conflicting records quarantine; incomplete runs never close missing jobs; incorrect merges can be reversed |
| S2-04 | Engineer: scheduled runs, leases, disable control, run logs, fixture checks | 1 day | Collection runs with browser closed; overlapping triggers and worker restart do not corrupt data; disabled sources stop running |

Dependencies: S1 decisions and source-fit exit. If one adapter lacks validated supply, add the next necessary adapter before declaring completion and re-estimate capacity.

Demo: run collection twice, inject one source failure, and inspect canonical records and source health.

Exit: FR-04–FR-06 pass with real selected-source samples and deterministic failure fixtures. Historical benchmark evidence remains unchanged.

## Sprint 3 — Deliver the private profile-to-shortlist flow (M2)

Goal: a student can set constraints and act on an explainable shortlist.

| ID | Work and accountable role | Estimate | Acceptance / output |
|---|---|---:|---|
| S3-01 | Engineer: authentication, private tables, ownership policies, protected read models | 2 days | Two-account and signed-out tests prevent cross-user access, ownership reassignment, and client writes to jobs/matches/operator privileges |
| S3-02 | Engineer: profile/preferences forms with explicit unknown handling and validation | 2 days | Required education, experience, availability, role, location, work mode, and salary choices persist; contradictory settings explain the correction |
| S3-03 | Engineer: deterministic eligibility and ranking with evidence-backed explanations | 2 days | Hard exclusions beat skill fit; salary units/ranges and remote restrictions follow documented rules; versions invalidate stale matches |
| S3-04 | Engineer: responsive shortlist/detail, save/applied/dismiss/undo, and feedback | 2 days | Loading, empty, degraded, stale, and closed states work; application clicks and self-reported applications remain distinct |

Dependencies: stable Sprint 2 records and source fixtures. Use the Sprint 1 labelled set for evaluation; do not quietly change labels to fit the implementation.

Demo: two students with different constraints receive different lists; changing preferences recomputes results; applied/dismissed jobs are suppressed from alert candidates.

Exit: FR-01–FR-03, FR-07–FR-09, and FR-12 pass. Core forms/actions work on mobile and with a keyboard; per-profile relevance and supply are reported together.

## Sprint 4 — Make daily delivery and lifecycle safe (M3)

Goal: a verified student receives one useful digest and can stop it reliably.

| ID | Work and accountable role | Estimate | Acceptance / output |
|---|---|---:|---|
| S4-01 | Engineer: verified destination, consent history, delivery settings, pause/unsubscribe | 2 days | Only the selected working channel appears; verification is server-owned; consent changes cancel unsent work |
| S4-02 | Engineer: outbox, schedule slots, timezone handling, adapter, and reconciliation | 3 days | Duplicate triggers, concurrent claims, DST, missed slots, restart, and timeout after provider acceptance are covered; ambiguous sends are reconciled or held for review |
| S4-03 | Engineer: final send-time selection and eligibility checks | 1 day | Up to five current unnotified jobs; no padding; changed preferences, closed/stale jobs, applied/dismissed actions, channel switches, and revoked consent suppress inappropriate sends |
| S4-04 | Engineer + operator: deletion requests, retention execution, minimal operational console | 2 days | Deletion stops future sends and removes/de-identifies related data; operator can review flags/failures, disable sources, and make bounded retries; students cannot obtain operator access |

Dependencies: Sprint 3 exit and a chosen provider with a verified test destination. Resolve freshness-age limit and missed-slot grace window before enabling the scheduler. Use test recipients for verification.

Demo: profile → collection → match → digest → external application link → mark applied → next digest suppresses that job. Pause or deletion during queued work prevents submission.

Exit: FR-10, FR-11, FR-13, and FR-14 pass, including failure injection. Provider acceptance is never presented as confirmed delivery/read; already-submitted messages cannot be recalled by pause.

## Sprint 5 — Verify and prepare the voluntary pilot (M4 entry)

Goal: demonstrate every P0 requirement and give the operator enough evidence to launch or delay the pilot.

| ID | Work and accountable role | Estimate | Acceptance / output |
|---|---|---:|---|
| S5-01 | Engineer + founder: rerun cohort evaluation and multi-day collection/delivery observation | 2 days active work | Report proposed targets: ≥90% top-five precision, <2% duplicates, <2% closed at send, 100% explanations, zero silent critical conflicts; include sample sizes, per-profile supply, coverage, and zero-match fraction |
| S5-02 | Engineer: integrated access, lifecycle, recovery, performance, and accessibility checks | 2 days | All P0 acceptance checks evidenced; proposed p95 shortlist target under two seconds tested at 50 concurrent users with test conditions recorded; worker/provider failure and restoration exercises documented |
| S5-03 | Engineer + operator: privacy-conscious events, cost reporting, runbook, support and escalation | 2 days | Activation and actions are measurable; collection/messaging/support costs are separated; operator can diagnose an injected failure and follow recovery steps |
| S5-04 | Founder + engineer: fix release blockers and stage voluntary recruitment | 2 days | Pilot participation, support owner, retention text, and channel controls are ready; founder records go/no-go and evidence links before recruiting approximately 50 students |

Dependencies: Sprints 1–4 complete. Start multi-day observation early in this sprint; active-work estimates do not shorten its elapsed observation window.

Exit: all P0 gates in the PRD pass, source supply meets the numeric thresholds agreed in Sprint 1, and the operator can support the flow. Quality targets remain proposed until explicitly adopted; any changed threshold needs a rationale recorded before evaluating release results. Delay rollout for failed access, consent, duplication, or useful-supply gates.

## Sprints 6–7 — Run the four-week pilot

Founder owns recruitment/interviews and weekly go/no-go; operator owns daily source/delivery review; engineer prioritises correctness and reliability fixes.

| Period | Focus | Review output |
|---|---|---|
| Sprint 6, pilot weeks 1–2 | Staged voluntary onboarding, daily audits, feedback and delivery fixes | Activation, per-profile useful supply, relevance, failures, pause reasons, and costs; compare source gaps with Sprint 1 |
| Sprint 7, pilot weeks 3–4 | Measure repeat useful actions, self-reported applications, time saved, successful exits | Four-week evidence report and prioritised next backlog; choose improve, narrow, expand, or stop |

Keep paid implementation out of these sprints. A concrete willingness-to-pay experiment can follow demonstrated usefulness; billing and faster-alert work require the separate M5 gates.

## Execution and definition of done

At planning, assign a named owner to every selected item and confirm availability against eight engineering days. Keep only one primary engineering workstream active. If work overruns, move unfinished items explicitly and recalculate dependent sprints.

An implementation item is done when its acceptance behavior is demonstrated, relevant automated checks pass, configuration/migrations reproduce the change, operational failure states are handled, and affected documentation is updated. Attach evidence to the item; a mock screenshot or passing happy path alone does not close a pipeline, access, or delivery requirement.

Use FR IDs in issue/PR descriptions. The tables cover all P0 requirements; FR-15–FR-17 remain deferred. At each sprint review record completed scope, unresolved failures, actual effort, and the next gate decision. The existing roadmap remains the milestone source of truth; this document is the proposed execution breakdown.

Immediate next step: assign the Sprint 1 founder and engineer, confirm capacity, and begin cohort interviews and evaluation preparation. No application scaffold or infrastructure provisioning is part of this planning change.
