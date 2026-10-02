# Role Ping — Launch, measurement, and testing

## College pilot

Proposed scope: approximately 50 voluntary students over four weeks, with a small number of role families and locations. Start with profile interviews and a manually reviewed recommendation sample before automating all delivery. Confirm the department/cohort, channel preference, and operational owner first.

Interview 12–15 students about their last actual search: sources used, time spent, eligibility problems, missed openings, and previous spending. Ask for examples rather than hypothetical enthusiasm. Use the college's employer history to seed the directory with permission where needed; do not import private student rosters or contact lists automatically.

Stage 1: collect profiles and review recommendations manually. Stage 2: deliver daily digests and fix errors. Stage 3: compare improved ranking with the baseline and invite voluntary referrals. Stage 4: test a concrete paid benefit only after useful results are demonstrated. Four weeks is a proposed experiment duration, not a delivery estimate.

## Product metrics

Primary product metric: weekly students reporting at least one application to a recommended job. Label this self-reported. Supporting metrics include time saved from before/after student surveys, recommendation relevance, repeat useful actions, referral activation, notification pause/unsubscribe reasons, and interviews reported.

| Metric | Definition |
|---|---|
| Activation | Confirmed profile/preferences plus first meaningful shortlist action within seven days |
| Meaningful action | Save, application click, self-reported applied, or explicit relevance feedback; report action types separately |
| Weekly voluntary retention | Activated users with meaningful optional action in week N / eligible activated cohort; separate hired/paused users |
| Apply-through | Self-reported applications / recommendations exposed; never substitute clicks without labelling |
| Referral activation | Referred signups that activate / referred signups |
| Useful recommendation cost | Total relevant operating cost / audited useful recommendations delivered |
| Successful exit | User pauses because they found a job/internship; separate from dissatisfaction churn |

Avoid optimising raw signups, mandatory attendance, messages sent, or app opens as the main success measure. If college registration is mandated, tag the acquisition cohort and measure voluntary use independently.

## Stronger benchmark

Use 20 representative profiles and a manually adjudicated job set from selected employer boards plus search sources. Run baseline JobSpy and the enhanced pipeline over the same collection window and source coverage. Evaluate identical profiles, log exclusions, and inspect both accepted and rejected jobs.

| Measure | Proposed initial target | Measurement rule |
|---|---:|---|
| Precision in top five | >=90% | Human-reviewed relevant and eligible recommendations / evaluated recommendations; also report per-profile results |
| Duplicate recommendations | <2% | Duplicate canonical vacancies within evaluation delivery window / deliveries |
| Closed at send time | <2% | Independently checked closed roles / audited deliveries |
| Fit explanation | 100% | Each recommendation has evidence-backed reasons and unresolved caveats |
| Silent critical-field conflict | 0 | No unresolved salary/eligibility contradiction treated as confirmed |
| Source run health | Measure before committing | Successful, empty, partial, blocked, timeout reported separately |
| Detection delay | Measure, no initial promise | Time between credible publication observation and first detection; report uncertainty |
| Reference-set coverage | Must accompany precision | Eligible reference jobs recovered / eligible reference jobs; do not equate with entire-market recall |

Targets are hypotheses, not achieved results. Require a useful supply per profile and report the fraction of profiles receiving zero matches; perfect precision from delivering almost nothing does not pass. The minimum acceptable supply and coverage target should be set after measuring the selected cohort's real opportunity pool.

Maintain the original benchmark as historical evidence. Its source mix, tiny sample, populated-field scoring, and one-host timing do not establish long-term uptime or fresh-post detection speed.

## Test plan

| Area | Meaningful checks |
|---|---|
| Connector wrappers | Valid response, legitimate empty result, 403/406/429, timeout, schema drift, pagination partial failure |
| Normalisation | Monthly vs yearly salary, INR vs other currency, absent fields, remote country restrictions, malformed URLs |
| Validation | Intern title with senior description; salary interval conflict; required vs preferred experience |
| Deduplication | Same source ID; shared employer URL; different requisitions with identical titles; merge reversal |
| Matching | Hard excluded location wins; salary unknown policy; range straddles floor; branch/batch conflict; profile change invalidates stale match |
| Delivery | Duplicate schedule triggers; timeout after provider acceptance; pause before send; channel change; no jobs; timezone/DST; expired job before send |
| Access control | Two students cannot read/write each other's data; clients cannot change jobs, matches, plan, or admin role; protected views remain protected |
| Billing later | Forged/replayed webhook; out-of-order cancellation/payment; entitlement expiry; duplicate provider events |
| End to end | Student creates profile → worker creates matches → digest → job detail → external link → marks applied → no repeat alert |
| Operations | Worker restart, lease recovery, provider outage, disabled source, backup restore |

Do not submit real job applications during automated verification. Use provider test modes and test recipients for delivery/billing checks.

## Event vocabulary

Suggested events: profile_confirmed, preferences_updated, match_exposed, job_saved, application_link_opened, application_marked, job_dismissed, feedback_submitted, digest_submitted, digest_delivered, alert_paused, referral_activated, subscription_started, and job_found_reported.

Version the event schema; use pseudonymous identifiers and avoid raw resumes/contact details in analytics. Some channels do not reliably expose reads, so do not compare read-rate metrics without acknowledging that limitation.

## Go/no-go decisions

Pilot gate: P0 flow and access tests pass; useful manually reviewed matches exist; consent and pause work; operator can diagnose failures.

Expansion gate: relevance and repeat voluntary usage are demonstrated; worst-profile gaps are understood; observed costs fit a plausible business model.

Paid gate: multi-day source monitoring, bounded delivery delay, entitlement/payment tests, and clear user-facing plan terms. Do not sell an unsupported freshness guarantee.
