# Live job-scraping benchmark — 2 October 2026

## Recommendation

Python JobSpy is the preferred job-board connector from this small live test. Combine it with direct employer-feed adapters. Do not use scraped salary, remote flags, title, or eligibility without a validation layer.

These scores describe this benchmark, not long-term uptime, total market coverage, legality of reuse, security, or production readiness. No scraping method was tested at scale.

## Test conditions

- Live execution on the user's macOS machine, beginning at 07:05 UTC / 12:35 IST. No account logins, paid proxies, CAPTCHA solving, or applications.
- Python JobSpy 1.2.0; ts-jobspy 3.0.1; Scrapy 2.19.0; Crawlee 3.18.2; Requests 2.34.2. Python 3.12.14; Node 26.8.1.
- Job-board tests: two queries, `software engineer intern` and `graduate engineer trainee`; Bengaluru; India; preceding 168 hours; request up to ten results per query per source. Indeed, Naukri, LinkedIn: six searches per library, twelve searches total.
- Description fetching enabled in Python; LinkedIn description fetching enabled in TypeScript. Other TypeScript sources use their native description behavior. No deduplication was requested.
- Libraries were interleaved and their order reversed for the second query. One search at a time; three-second gaps. Parent process timeout 90 seconds; TypeScript per-source timeout 60 seconds.
- Framework tests: three public employer JSON feeds, twice through each of Requests, Scrapy, and Crawlee; eighteen fetches. Order reversed on repetition. These test JSON retrieval, not browser rendering, HTML extraction, anti-bot resilience, or large crawling queues. Retries disabled for Scrapy and Crawlee.
- Wall time includes subprocess startup and imports. It is relevant to short-lived workers, not a pure network-speed or persistent-service benchmark. Runs occurred on one host/network; location-specific behavior and cache effects were not isolated.
- Initial sandbox DNS restrictions were resolved before measured execution. Dependency installation is excluded from timing.

## Job-board results

| Library | Source | Nonempty successful searches | Returned records | Median wall time | Descriptions >100 characters | Posting date present | Plausibly fresher-suitable |
|---|---|---:|---:|---:|---:|---:|---:|
| Python JobSpy | Indeed | 2/2 | 9 | 8.36 s | 9/9 | 9/9 | 5/9 |
| Python JobSpy | Naukri | 2/2 | 16 | 2.39 s | 16/16 | 9/16 | 11/16 |
| Python JobSpy | LinkedIn | 2/2 | 20 | 11.05 s | 20/20 | 20/20 | 18/20 |
| ts-jobspy | Indeed | 2/2 | 9 | 0.70 s | 9/9 | 9/9 | 5/9 |
| ts-jobspy | Naukri | 0/2 | 0 | 0.50 s to failure | N/A | N/A | N/A |
| ts-jobspy | LinkedIn | 2/2 | 20 | 31.07 s | 20/20 | 20/20 | 18/20 |

Naukri returned HTTP 406 in both TypeScript attempts. Python returned 45 records total; TypeScript returned 29. These are records, not deduplicated vacancies. All common-source URLs matched across the libraries in this sample. Returning fewer than ten records is not automatically a failure; the request is a cap, not proof that ten matches exist.

### Ratings out of ten

| Library | Retrieval success | Core field presence | Fresher suitability | Speed | Overall |
|---|---:|---:|---:|---:|---:|
| Python JobSpy | 10.0 | 9.7 | 7.6 | 6.0 | **8.7** |
| ts-jobspy | 6.7 | 10.0 | 7.9 | 4.0 | **7.7** |

Overall = 30% retrieval + 25% core field presence + 35% fresher suitability + 10% speed. Scores are calculated at full precision before rounding.

- Retrieval = ten times the fraction of searches returning records without reported failure. A legitimate empty search would need a different interpretation in a larger benchmark; here both empty searches explicitly failed.
- Core field presence = ten times the fraction of six populated fields: title, company, job URL, location, description >100 characters, posting date. It measures presence, not correctness or city precision. Python: 263/270 populated fields. TypeScript: 174/174.
- Fresher suitability = ten times the proportion manually judged plausibly suitable for an engineering student/recent graduate with no mandatory professional tenure: Python 34/45; TypeScript 23/29. Projects/coursework/internships may satisfy skills. Explicit required professional experience, conflicting content, and unclear training offers fail this screen. This is analyst judgment, not employer confirmation or eligibility for a specific student's branch, batch, or availability. It measures broad fresher usefulness rather than exact keyword relevance. Per-record explanations are in job-audit.csv.
- Speed uses median wall time of successful searches: <=2 seconds =10; <=5 =8; <=15 =6; <=30 =4; <=60 =2; otherwise =0. Medians were 6.75 seconds for Python and 15.31 seconds for TypeScript. Failed fast requests receive no speed benefit.
- Field presence and suitability are conditional on returned records. TypeScript's failed Naukri connector means those categories sample a narrower set. The retrieval score separately penalizes this failure.

## Employer-feed and framework results

The boards were Razorpay on Greenhouse (21 jobs), Safe Security on Lever (16), and CertifyOS on Ashby (14). These were full employer boards, with multiple seniorities, locations, and roles. Their 51 distinct source records must not be compared with the fresher search totals.

| Fetch method | Successful fetches | Payloads identical to baseline | Median wall time | Retrieval /10 | Preservation /10 | Speed /10 | Overall /10 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Direct API using Requests | 6/6 | 6/6 | 0.89 s | 10 | 10 | 10 | **10.0** |
| Scrapy | 6/6 | 6/6 | 2.11 s | 10 | 10 | 8 | **9.6** |
| Crawlee HTTP crawler | 6/6 | 6/6 | 2.22 s | 10 | 10 | 8 | **9.6** |

For this separate test only, overall =40% successful retrieval +40% exact JSON payload preservation +20% speed using the same timing buckets. A 10/10 means passing this small JSON-fetch task; it does not mean a perfect general-purpose scraper. These ratings are not comparable with the JobSpy ratings, which include matching usefulness. The two crawler frameworks have capabilities this benchmark does not exercise.

## Findings that matter for the product

1. Python's Naukri output included a software-intern title paired with a senior digital-marketing description and a direct URL mentioning UI/UX. The benchmark establishes inconsistent output; it does not establish whether the source, redirection, or extractor caused it. Quarantine such records.
2. Some intern results required 1–2 years of professional coding experience. A graduate trainee result required about one year of professional networking experience. Title-only filtering would admit these.
3. Python returned structured salary in 6/45 records; TypeScript in 0/29. A Weekday LinkedIn record returned INR 300,000–600,000 yearly in Python, while its description stated INR 30,000–50,000 monthly. Python also returned `is_remote=false` while the description said remote; TypeScript returned true. Structured salary presence is therefore not a salary-accuracy score.
4. Python's Naukri result dates were missing in 7/16 records. Indeed location fields were state/country (`KA, IN`), not city. Preserve unknowns and distinguish inferred locations from explicit ones.
5. A returned Hitachi description included an older publication date than the job-board listing date. This snapshot cannot establish genuinely new openings, repost detection, or publication-to-detection latency.
6. Similarly titled Pointo listings had differing descriptions; do not automatically collapse vacancies using title/company alone.

## Link spot checks

Fifteen job pages were requested using ordinary Python Requests: three each from Indeed, Naukri, LinkedIn, and two each from the three employer boards.

- Indeed: 3/3 returned HTTP 403; cannot determine whether the jobs are closed or accessible to a normal browser from that result.
- Naukri: 3/3 returned HTTP 200 but no expected title in parsed page text; status alone did not validate a usable job page.
- LinkedIn: 3/3 returned HTTP 200 and expected titles.
- Employer boards: 6/6 returned HTTP 200 and expected titles.
- No forms were submitted. These checks do not certify that an application can be completed.

## Implementation decision

Use Python JobSpy as a replaceable discovery connector. LinkedIn produced the strongest fresher-suitable sample; Naukri added coverage but needs stricter validation. Use lightweight direct adapters for employer feeds. Add Scrapy when valuable custom HTML sites require it, or Crawlee when a JavaScript/browser workflow genuinely requires it. This test does not establish either framework's advantage for those later tasks.

Before charging for speed, run repeated monitoring over days with source health logs, exact first-seen timestamps, schema checks, closed-job tracking, deduplication and per-profile relevance. The current benchmark is a short live smoke test, not a sustained reliability benchmark.

## Files

- scraper-ratings.csv: calculated library scores.
- source-results.csv: individual library/source measurements.
- framework-ratings.csv: separate JSON-fetch test.
- job-audit.csv: returned job metadata, links, and manual suitability notes; full descriptions intentionally omitted.
- measurements.json: timing, errors, feed runs, and link checks.
- versions.json: dependency versions.
- benchmark-code.zip: scripts and package lock for reproduction; excludes installed dependencies and full scraped descriptions.
