# Role Ping — Product Documentation

Version 0.2 · 2 October 2026 · Product name: Role Ping

This folder turns the product discussion and live scraping benchmark into a buildable product specification. It contains planning documents, not a deployed application. Proposed defaults, launch targets, and architecture recommendations are explicitly identified; they are not claims of validated demand or approved implementation choices.

## Product in one sentence

Students provide their profile and preferences; Role Ping finds, checks, and ranks relevant jobs, then delivers a small shortlist through their chosen channel so they spend less time searching and more time applying.

## Read in this order

1. [Product description and strategy](docs/01-product-description.md) — problem, audience, positioning, business model, and distribution.
2. [Product requirements document](docs/02-PRD.md) — scope, user stories, requirements, acceptance criteria, and release gates.
3. [Architecture and data model](docs/03-architecture-and-data.md) — frontend + Supabase + Python worker, trust boundaries, tables, and operations.
4. [Collection, validation, and matching](docs/04-job-data-engine.md) — sources, quality rules, deduplication, freshness, and ranking.
5. [User experience, delivery, and plans](docs/05-experience-and-plans.md) — screens, schedules, channel contracts, and proposed monetisation.
6. [Launch, measurement, and testing](docs/06-launch-and-validation.md) — college pilot, product metrics, quality benchmark, and test plan.
7. [Roadmap and future enhancements](docs/07-roadmap.md) — dependency-based milestones and deferred features.
8. [Decisions, risks, and open questions](docs/08-decisions-and-risks.md) — what came from the user, what is recommended, and what remains unresolved.
9. [Directory review and sprint plan](docs/09-sprint-plan.md) — proposed capacity, sprint backlog, dependencies, acceptance checks, and pilot gates.

## Recommended MVP

- Responsive web app connected to Supabase for authentication and permitted data operations.
- Scheduled Python worker using Python JobSpy and direct employer job feeds.
- Profile, preferences, ranked jobs, explanations, saved/applied/dismissed actions, and feedback.
- A daily digest of up to five qualifying new jobs, proposed default 7 a.m. in the user's selected timezone.
- Email as a provisional first delivery channel; official WhatsApp integration after channel economics and consent flows are validated.
- Voluntary pilot with approximately 50 students; expand only after job relevance and collection reliability are demonstrated.

The software must enforce personal-data ownership and paid entitlements server-side. A separate Django/FastAPI service is not required for the MVP, but server-side workers/functions are required.

## Benchmark evidence

The [live benchmark report](evidence/job-scraping-benchmark/REPORT.md), [source results](evidence/job-scraping-benchmark/source-results.csv), [job audit](evidence/job-scraping-benchmark/job-audit.csv), and [measurements](evidence/job-scraping-benchmark/measurements.json) are included unchanged.

Python JobSpy scored 8.7/10 and ts-jobspy 7.7/10 on the original weighted snapshot. These are not production reliability ratings. Requests, Scrapy, and Crawlee were tested separately on simple employer JSON feeds; their scores are not comparable with the JobSpy scores.

## Status and ownership

Product owner: founder. Engineering and operations owners: to be assigned. College contact: to be agreed through an appropriate pilot arrangement. No users have been onboarded, no providers selected or provisioned, and no pricing or launch date has been committed by these documents.

When decisions change, update the decision log and affected requirements together. Preserve benchmark timestamps and methodology instead of presenting old measurements as current guarantees.

## Repository layout

```text
RolePing/
├── README.md
├── docs/                     # Product requirements, architecture, and roadmap
└── evidence/
    └── job-scraping-benchmark/ # Historical measurements and reproduction archive
```

This repository currently contains the product specification and benchmark evidence. Application code has not been scaffolded. Add application and worker directories when their implementation starts; avoid empty placeholder projects.

The benchmark-code ZIP is retained as the original reproduction artifact. Redundant document exports and duplicate folders have been removed. Raw scrape payloads, local environments, and credentials are not included.

## Development workflow

- Read the PRD and decision log before changing scope or architecture.
- Use short-lived branches from `main` and make focused commits describing the resulting change.
- Keep requirement changes and their decision-log entries together.
- Store real credentials only in ignored local environment files; commit sanitised `.env.example` files when configuration is introduced.
- Preserve historical benchmark measurements. Put future runs in separately dated evidence directories with their methodology and dependency versions.
- Run implementation-appropriate checks and verify documentation links before committing. No application test suite exists yet.
