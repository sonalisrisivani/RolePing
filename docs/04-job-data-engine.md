# Role Ping — Collection, validation, and matching engine

## Evidence-informed source strategy

Start with Python JobSpy for broad discovery and small direct adapters for relevant employer boards. Use custom Scrapy/Crawlee connectors only when valuable coverage is missing. Commercial APIs remain candidates for a later matched benchmark; none was tested or selected in this conversation.

Sources and references:

- [Python JobSpy](https://github.com/speedyapply/JobSpy): discovery adapter; isolate failures per source.
- [Greenhouse public job-board API](https://docs.greenhouse.io/job-board.html), [Lever postings API](https://github.com/lever/postings-api), [Ashby postings API](https://developers.ashbyhq.com/docs/public-job-posting-api): direct employer adapters.
- [Scrapy](https://github.com/scrapy/scrapy), [Crawlee](https://github.com/apify/crawlee): future custom crawling infrastructure.

Maintain a registry of employers, verified board identifiers, permitted access/reuse conditions, source cadence, and expected output shape. Public accessibility and an open-source library licence are distinct from source reuse terms. Start with the college's relevant employers, not an arbitrary large worldwide feed list.

## Connector contract

Input: source configuration, shared query/board, pagination cursor if supported, time window, request budget, and run ID.

Output: source-native identifiers and links; source-reported timestamps; raw content or reference; parsed fields; pagination/completeness indicators; duration; and outcome classified as success, empty, partial, rate_limited, blocked, schema_error, timeout, or unavailable. These statuses are internal conventions to implement, not assumptions about library return values.

A wrapper must interpret JobSpy logs/results carefully: an empty dataframe is not automatically a successful zero-match search. No new UI registration should directly trigger an unrestricted scrape.

## Job representation

Preserve employer, title, role family, employment type, description, application/source links, locations, work mode, geographical remote restrictions, experience bounds, graduation/degree restrictions, skills, compensation, source identity, and evidence timestamps.

Every extracted decision-critical field should have a value, provenance, evidence snippet/reference, extraction method/version, confidence, and conflict/unknown state. Compensation requires amount/range, currency, period, and whether it is stipend, base, or total compensation when known. Avoid presenting annualised internship stipends as guaranteed full-year income.

Store at least published_at (source claim), source_updated_at, first_seen_at (our observation), last_seen_at (successful collection), last_checked_at, and status_checked_at. Do not substitute first_seen for publication date. A newly discovered historic board must not create instant “newly posted” notifications for every old role.

## Processing stages

1. Fetch with a bounded source budget and record run health.
2. Upsert source records by stable identifiers; preserve original content/evidence according to retention policy.
3. Normalise spelling/location aliases and structured fields while retaining originals.
4. Validate source identity, link shape, field contradictions, and mandatory content.
5. Map source records to canonical jobs conservatively.
6. Extract eligibility and compensation evidence; flag uncertainty/conflicts.
7. Evaluate job state and freshness from successful observations.
8. Filter hard constraints, then rank eligible jobs per profile.
9. Publish match records with versions and reasons; enqueue candidates for later delivery checks.

An optional language model can interpret complex descriptions. Validate its structured output and evidence; never allow an unsupported model statement to establish salary, citizenship, branch, or graduation eligibility. Process a job once where possible and cache by content/extractor version. Resume/job text is untrusted data, not instructions to execute tools or disclose secrets.

## Deduplication

High-confidence joins: identical source ID on the same source; identical canonical employer application URL; verified employer requisition ID. Supporting signals: normalised employer, title, location, and description similarity.

Normalise tracking parameters cautiously; keep parameters needed to identify the vacancy. Similar titles at the same employer can represent different teams or requisitions. Retain multiple source records and their history even when merged. Permit an operator to split an incorrect merge. Suppress repeated alerts at canonical-job level, not only source URL level.

## Eligibility rules

Use three states per hard criterion: pass, fail, unknown. Any explicit fail excludes the job from the qualifying shortlist. Unknown never becomes pass simply because skill similarity is high.

| Criterion | Required treatment |
|---|---|
| Experience | Required professional tenure above the profile excludes; optional experience does not automatically exclude. Projects and internships count only where the posting permits them. |
| Role type | Internship/full-time/contract must match the selected hard constraint. |
| Geography | Explicit excluded location or ineligible country restriction excludes. “Remote” does not mean work from any country. |
| Graduation/degree | Compare explicit restrictions; show uncertainty if absent. Batch/degree-specific student eligibility still needs checking. |
| Salary | Compare like currency and period; flag variable/total compensation. Missing compensation follows the user's include/exclude policy. |
| Salary range | If maximum is below the floor, fail. If minimum meets the floor, pass. If only part of the range meets it, mark uncertain and include only when the user accepts such ranges. |
| Availability | Exclude known start/duration conflicts; display unresolved requirements. |
| Skills | Required skills contribute evidence and constraints only where genuinely mandatory; preferred skills affect rank. |

Proposed defaults: include undisclosed salary only with explicit onboarding acknowledgement; show unknown degree/batch details as a caveat in the app; require stronger verified fit for rapid outbound alerts. Let users opt into a strict “confirmed eligibility only” mode. Final onboarding defaults remain a product decision.

## Ranking after eligibility

Initial proposed deterministic score: role fit 35%, skill evidence 25%, location/work-mode preference 20%, recency evidence 10%, source/data quality 10%. Weights are tunable hypotheses, not trained or validated values. Hard filters always precede ranking.

Explain meaningful reasons without a misleading “97% chance of selection.” Rank candidates by fit and known freshness; use stable tie-breaking. Rerank when profile preferences or job content change. Keep rejected/uncertain examples for evaluation and operator review under retention rules.

## Job lifecycle

Suggested states: active, uncertain, closed, quarantined. An explicit closed response or reliable employer status can close a job. Absence from two complete successful employer-board snapshots is a proposed conservative closure rule, subject to source semantics. A failed, truncated, or paginated-incomplete request cannot close missing jobs. Reopening a job does not automatically justify another alert; compare material changes and user history.

Before delivery, use a configurable evidence-age limit and recheck status where supported. “Recently detected” describes observation; “recently posted” requires credible source publication evidence. The paid promise must refer to time after detection, not an unmeasured advantage over other applicants.

## Live benchmark implications

The included [benchmark report](../evidence/job-scraping-benchmark/REPORT.md) records 45 Python results, 34 plausibly fresher-suitable, versus 29 TypeScript results, 23 plausible. TypeScript Naukri failed twice. Returned records included title/description contradictions, salary/remote conflicts, and missing dates. These failures motivate this processing layer; a more populated schema is not proof of accurate matching.

The three tested employer boards returned 51 total records across all roles and locations. This is neither 51 fresher matches nor an estimate of Indian market coverage. Wider employer selection and repeated monitoring are still required.
