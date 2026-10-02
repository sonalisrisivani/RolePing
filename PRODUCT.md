# Role Ping product brief

Role Ping helps users find relevant jobs and internships, check important eligibility details, and receive a small shortlist. Users control their profile, preferences, and notifications.

## First useful flow

1. A user signs in and sets target roles, locations, compensation policy, and delivery preferences.
2. A separate worker collects jobs from selected sources, preserving source identity, evidence, timestamps, and collection health.
3. Matching excludes explicit hard-constraint failures, flags unknown eligibility, and ranks current jobs.
4. A user reviews a private shortlist and can save, dismiss, or mark a role applied.
5. A delivery worker sends only current, undelivered matches after consent and final eligibility checks.

## Required safeguards

- A user can access only their own private data. The browser cannot write jobs, matches, entitlements, or operator state.
- Source failures are isolated. Partial collection cannot close missing jobs.
- Unknown salary, degree, batch, location, or freshness cannot be presented as confirmed.
- A digest is never padded with unsuitable jobs; a delivered job is not resent as new.
- Pausing stops future sends. Account deletion stops delivery and removes or de-identifies personal data under an approved retention policy.

The proposed digest contains up to five jobs around 07:00 in the user's selected IANA timezone. Changeable and unresolved values are in [product-rules.json](config/product-rules.json). Paid faster alerts are deferred until source quality and delivery reliability are measured.

The current build implements email sign-in, a profile and preference form, and private Supabase profile storage. Hosted database preference save/reload and cross-account isolation checks pass; signed-in browser save/refresh still needs end-to-end verification. Job collection, matching, delivery, operator tools, and billing remain to be built.
