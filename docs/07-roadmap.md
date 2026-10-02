# Role Ping — Roadmap and future enhancements

Sequence is dependency-based. Dates, staffing, budget, and implementation estimates remain open.

## Milestones

| Milestone | Deliverable | Exit criteria |
|---|---|---|
| M0 — Audience and source fit | Target cohort, 20 test profiles, employer registry, provider shortlist | Selected sources contain a useful relevant pool; outstanding choices recorded |
| M1 — Data foundation | JobSpy wrapper, employer adapters, source logs, canonical jobs, validation | Bounded runs, error separation, provenance, deduplication, and parser checks pass |
| M2 — Student product | Auth, profile/preferences, match list, explanations, actions | Ownership tests and profile-to-shortlist flow pass |
| M3 — Daily delivery | One verified channel, outbox, scheduling, pause, operator review | No duplicate/revoked sends in failure tests; daily end-to-end flow passes |
| M4 — Voluntary college pilot | Approximately 50 students, four-week experiment, feedback loop | Quality, coverage, engagement, and costs measured; fixes prioritised |
| M5 — Paid convenience | Faster alerts, watchlists/searches, billing, plan enforcement | Sustained monitoring and paid-launch gates pass; pricing supported by tests |
| M6 — Expansion | More branches, employers, colleges, channels | Each expansion preserves quality and unit economics |

## Enhancement backlog

| Enhancement | User benefit | Dependency / reason to defer |
|---|---|---|
| Resume import and confirmed extraction | Faster onboarding | Secure file handling, retention, and user review of inferred fields |
| Resume generation/tailoring | Useful output from an existing profile | Proven discovery value; never fabricate experience |
| Additional channels: WhatsApp, Telegram, push | Delivery where users prefer | Official integration, channel consent, costs, adapter reliability |
| Company watchlists | Focused monitoring of desired employers | Reliable employer directory and freshness history |
| Multiple saved searches | Separate internship/full-time or city choices | Clear collision/deduplication and notification controls |
| Application reminders and tracking | Help students follow through | User-reported status, reminders opt-in, no false submission claims |
| Better semantic matching | Interpret adjacent roles and skills | Labeled evaluation set; rules continue to enforce hard constraints |
| Commercial job-data provider | Reduce maintenance or fill coverage gaps | Matched quality/cost benchmark and reuse review |
| Custom employer crawlers | Recover valuable missing sources | Proven audience demand and maintainable extraction tests |
| Skill-gap suggestions | Explain repeated near matches | Accurate required/preferred skill extraction; not a gate to seeing jobs |
| Interview preparation / peer practice | Help after discovery | Separate demand validation; avoids bloating initial product |
| College operations dashboard | Help placement teams coordinate | Define institutional buyer needs and aggregate/private-data boundaries |
| Public profile/portfolio | Share achievements | Explicit publication controls; private-by-default design |
| Native mobile app | Improve habitual access | Evidence that responsive web and chosen channels are insufficient |
| Public API / SDK | Serve other developers or institutions | Real external demand, versioning, quotas, contracts, support |
| Auto-apply | Reduce application effort | Explicit per-user authorisation, accurate reviewed answers, platform compatibility, application audit; separate product decision |

Auto-apply is not implied by the current scope. The MVP supplies links and leaves application submission to the student. Public SDK work is also deferred: owning an internal API boundary does not require publishing a developer product.

## Expansion principles

Add a new role family only after testing its eligibility rules and source supply. Add a new college without relying on forced engagement. Add a new country only after handling work authorisation, local compensation conventions, timezone behavior, source coverage, and relevant operational requirements. Do not infer citizenship or work authorisation from location.

Revisit architecture when measured needs justify it: dedicated API for substantial synchronous logic/multiple clients; queue partitioning for larger workloads; a separate search index for demonstrated query needs; embeddings after evidence they improve outcomes; specialised providers after proven coverage/cost advantages.
