# Role Ping — Product requirements document

Status: Draft specification · Version 0.2 · Product name: Role Ping

## Objective

Help a student discover and act on suitable openings with less manual searching. Deliver a trustworthy small shortlist based on their confirmed profile, explicit preferences, and current job information.

## Goals and non-goals

MVP goals: validate source coverage for a narrow cohort; produce explainable matches; support daily delivery; capture actual user feedback; measure reliability and cost. Core processing must work without students keeping the app open.

MVP excludes automatic job applications, resume generation, interview coaching, a social feed, recruiter messaging, a public developer SDK, native mobile apps, and a broad college ERP. It does not promise complete market coverage, exact publication-time delivery, or guaranteed salary/eligibility when undisclosed.

## Primary journey

Sign up → confirm profile → choose constraints and delivery settings → receive/read shortlist → inspect fit and caveats → open employer/job application page → optionally mark applied → provide feedback → refine subsequent matches.

Opening an application URL is a click event, not proof of application. Users submit applications directly on the destination site in the MVP.

## Functional requirements

| ID | Priority | Requirement | Acceptance criteria |
|---|---|---|---|
| FR-01 | P0 | Authentication and private accounts | A signed-in student can read/edit their own profile; another account and a signed-out client cannot access it. |
| FR-02 | P0 | Profile onboarding | Capture education/branch, graduation year, student/graduate status, skills, professional experience separately from projects/internships, preferred roles, and availability. Users can correct all inferred fields. |
| FR-03 | P0 | Preference controls | Capture role type, included/excluded locations, remote/hybrid/onsite choice, salary floor with currency/period, unknown-salary policy, and strict versus preferred criteria. Contradictory settings produce a clear validation message. |
| FR-04 | P0 | Shared job collection | Scheduled sources run without frontend visits; each run records status, counts, timings, and errors. One broken source does not discard healthy-source results. |
| FR-05 | P0 | Normalisation and validation | Preserve provenance and uncertainty. Contradictory title/description or salary fields are flagged; no invented values fill unknown fields. |
| FR-06 | P0 | Duplicate management | Repeated source IDs update existing records. Confident cross-source duplicates share one canonical job. Distinct requisitions are not merged only because titles match. |
| FR-07 | P0 | Eligibility and ranking | Explicit hard exclusions win over positive skill matches. Matches show fit reasons and unresolved eligibility conditions. Engine version is recorded. |
| FR-08 | P0 | Personal shortlist | Show ranked qualifying jobs with title, employer, location, compensation if known, age label, reasons, caveats, and application link. Empty states do not fabricate matches. |
| FR-09 | P0 | Job actions | Save, unsave, mark applied, undo applied, dismiss, and report a problem. Applied/dismissed jobs are excluded from later alerts unless the user explicitly resets the action. |
| FR-10 | P0 | Daily digest | Proposed default 07:00 in selected timezone, maximum five qualifying new jobs. Verify current preferences, job status, prior delivery, and consent before sending. Do not pad or replay old backlog as new. |
| FR-11 | P0 | Delivery settings | Verified destination, affirmative channel choice, pause/unsubscribe, timezone, and schedule. Changes affect queued delivery before its next attempt. |
| FR-12 | P0 | Feedback | Record wrong location, too experienced, salary issue, expired, duplicate, irrelevant role, and other feedback. Feedback never silently relaxes hard constraints. |
| FR-13 | P0 | Operator controls | Review source health, quarantined jobs, delivery failures, and reported records; disable a source and retry bounded failures. Privileges are server-assigned. |
| FR-14 | P0 | Account lifecycle | Allow alert pause and an account deletion request. Remove or de-identify personal data under the documented retention policy; prevent further sends. |
| FR-15 | P1 | Faster paid alerts | Server-confirmed entitlement permits shorter delivery delay for qualifying newly detected jobs. Quiet hours and notification caps still apply. No exact publication-time guarantee. |
| FR-16 | P1 | Billing | Signed webhook verification and idempotent processing update entitlements. Clients cannot set their plan or payment status. Failed/replayed events do not grant unintended access. |
| FR-17 | P1 | Share/referral | Public job links and invitation attribution disclose no private profile or application details. No automatic invitations to contacts. |

P0 defines the pilot release. P1 follows evidence of useful recommendations and delivery economics; launch order can be revised explicitly.

## Edge cases and required behavior

- Zero qualifying jobs: display the reason when known and invite an explicit preference change. Default to no empty outbound digest; this setting is proposed.
- Fewer than five: send fewer. More than five: rank the pool at delivery time; remaining jobs stay eligible only while fresh and relevant.
- Unknown salary: follow the student's explicit include/exclude setting and display “undisclosed.” A salary range crossing the floor is “may meet target,” not a guaranteed match.
- Remote role restricted to another country: do not equate remote with globally available.
- Missing batch/degree details: do not label eligibility as confirmed. Strict unknown-handling behavior is specified in the matching document.
- Source outage: retain provenance and last-check time; do not mark every unseen job closed. Suppress alerts if evidence is too stale under the configured delivery policy.
- First collection of an employer board: label entries “first found,” not “just posted.” Avoid a paid instant-alert flood from historical backfill.
- Resume parsing, if added later: ask the student to confirm extracted facts before they influence hard filters.

## Nonfunctional requirements

- Security: least-privilege data access; secrets remain server-side; private resume/contact data is not placed in public URLs or application logs.
- Reliability: bounded requests, retry backoff, idempotent database writes, queue recovery, and explicit empty-versus-error states.
- Performance: proposed pilot target p95 shortlist response under two seconds for 50 concurrent users, excluding external application sites. Load-test before claiming it.
- Accessibility: keyboard-operable core actions, labelled inputs, readable contrasts, mobile layouts, and accessible error states; target WCAG 2.2 AA during implementation.
- Transparency: expose evidence age and uncertainty; never imply extraction accuracy merely because a field is populated.
- Maintainability: versioned connector contracts, pinned dependencies, parser fixtures, and source-level isolation.

## Release gates

Before pilot: P0 acceptance checks pass; privacy ownership tests pass; selected sources supply a useful sample; a full profile-to-digest-to-application-link flow succeeds; duplicate sends and unsubscribe behavior are tested.

Before paid launch: sustained monitoring and quality evaluation meet the targets in [launch and validation](06-launch-and-validation.md); costs are measured; billing and entitlement tests pass; delivery claims reflect demonstrated capability. Initial benchmark ratings alone do not satisfy these gates.
