# Role Ping — Decisions, risks, and open questions

## Decision log

| Topic | Status | Basis / next action |
|---|---|---|
| Personalised job discovery and delivery | User direction | Replaces standalone resume maker as the core concept |
| Skills, salary, included/excluded locations | User direction | Formalised with strict/preferred and unknown-value handling |
| Free scheduled digest; paid faster alerts | User proposal | Validate usefulness, cadence, willingness to pay, and costs |
| Five jobs at 7 a.m. | Example from user; proposed default | Use up to five; confirm timezone and permit controls |
| College as initial distribution | User context | Pilot scope and institutional arrangement unresolved |
| Mandatory registration | User considered | Recommendation: voluntary pilot; separate voluntary metrics if mandated |
| JobSpy versus own scraping library | Recommendation | Own data/matching layer; reuse replaceable connectors |
| Python JobSpy | Evidence-backed recommendation | Better composite result in the small live benchmark; not a guarantee |
| Direct employer feeds | Recommendation | Successful simple-feed tests; wider relevant employer coverage unproven |
| Frontend directly to managed backend | User asked; recommended design | Requires correct grants/policies and separate privileged execution |
| Supabase over Firebase | Recommendation, not final approval | Relational data fit; no platform provisioned |
| Dedicated backend framework | Defer | Python worker and small privileged handlers still needed |
| Email first | Proposed scope choice | User wants channel choice; confirm pilot preferences before integration |
| Product name | User decision | Role Ping; documentation renamed accordingly |
| Pricing, visual identity, domain, hosting, billing provider | Open | No values/vendors committed; name/domain availability not verified |
| Resume maker, auto-apply, public SDK | Future/deferred | Not MVP requirements |

## Risk register

| Risk | Impact | Mitigation / trigger |
|---|---|---|
| Connector blocked or changed | Missing matches | Per-source health, bounded retries, disable switch, alternative feeds |
| Misleading source content | Ineligible recommendations | Evidence, conflict quarantine, feedback, human audits |
| Salary/remote parsing wrong | Hard filters fail user expectations | Provenance, unit checks, uncertainty, conservative interpretation |
| Low source supply | Good precision but little value | Coverage floor, reference-set recall, relevant employer expansion |
| Stale/reposted jobs | Paid speed proposition weak | Separate dates; status checks; multi-day monitoring |
| Duplicate alerts | Trust and cost damage | Canonical identity, send guards, reconcile ambiguous provider outcomes |
| Excessive notification frequency | Unsubscribes | Quiet hours, caps, digest batching, easy pause |
| Mandatory adoption distorts retention | False demand signal | Voluntary pilot/cohort metrics; no paid academic dependency |
| College access exposes private data | Loss of trust | Student ownership; no default admin access to personal preferences/activity |
| Messaging/collection cost exceeds revenue | Unsustainable plans | Measure marginal/shared costs; cap delivery; price from evidence |
| Source rights/provider terms unclear | Operational interruption | Record conditions and permitted use before enabling a source |
| Overbroad privileged keys | Data exposure | Server-only secrets, least privilege, access tests, operational review |
| Feature expansion before product value | Slow launch | Milestone gates and explicit deferred backlog |

## Questions to resolve before implementation

1. Which college cohort, branches, graduation years, and initial role families are in scope?
2. Which cities and remote arrangements matter most? Is the initial market India-only?
3. Is Supabase the final choice, and what frontend stack does the builder know?
4. Who will host and operate the Python worker, and what is the monthly pilot budget?
5. Do pilot students prefer email or WhatsApp enough to change channel launch order?
6. Which historical college employers can seed a relevant directory?
7. What exact unknown-eligibility defaults should onboarding use?
8. Who reviews flagged jobs, and how quickly can they respond during the pilot?
9. What retention/deletion settings and contact verification flow will be published?
10. What minimum opportunity supply makes the service useful for each profile?

Before monetisation additionally resolve pricing, billing/refunds, alert caps, supported channels, cancellation behavior, and measurable freshness claims. These do not block a manually supervised free pilot once its own prerequisites are met.

## Evidence and references

- [Original benchmark report](../evidence/job-scraping-benchmark/REPORT.md), [measurements](../evidence/job-scraping-benchmark/measurements.json), [manual job audit](../evidence/job-scraping-benchmark/job-audit.csv).
- [Python JobSpy](https://github.com/speedyapply/JobSpy) and [TypeScript JobSpy](https://github.com/alpharomercoma/ts-jobspy): libraries actually tested at the versions recorded in the benchmark.
- [Greenhouse](https://docs.greenhouse.io/job-board.html), [Lever](https://github.com/lever/postings-api), [Ashby](https://developers.ashbyhq.com/docs/public-job-posting-api): direct-source integration references.
- [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) and [function limits](https://supabase.com/docs/guides/functions/limits): architecture references checked during documentation. The changelog Markdown endpoint failed to load; current implementation details must be rechecked when building.
- [WhatsApp business policy](https://whatsappbusiness.com/policy/): recheck at integration time. No provider tariff, template classification, or delivery guarantee is assumed in the plan.

The documentation includes no new live scraping run. It preserves the measurements from the earlier run on 2 October 2026. No scores in this folder should be read as independent third-party certification.
