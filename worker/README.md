# Job collection

This slice collects one employer's published postings from the [Greenhouse Job Board API](https://docs.greenhouse.io/job-board.html). The proposed initial board is [Razorpay](https://job-boards.greenhouse.io/razorpaysoftwareprivatelimited). Source choices and HTTP limits live in `config/product-rules.json`. No scheduler runs yet; collection cadence remains an open product decision.

## Run against the existing project

From the repository root, with Python 3.10+ and the installed, authenticated Supabase CLI:

```sh
python3 -m worker.collector --source razorpay --project-ref bqsjlmftpxawctenzvja
```

This fetches public data and uses the CLI's Management API transport for a manual operator run. Each import switches to `roleping_collector` before accessing collection data. The CLI's operator login itself remains privileged; do not deploy that login as a scheduled worker credential. It is not copied or stored by this program.

For a future dedicated worker, provision a separate database login granted only `roleping_collector`, install `worker/requirements.txt`, set the server-only `ROLEPING_DATABASE_URL` (see `.env.example`), then run:

```sh
python3 -m worker.collector --persist
```

The driver is pinned, installed and import-tested locally. The dedicated-login transport has not been verified against hosted Postgres because no dedicated login has been provisioned. No new password is needed for the verified manual CLI path. Keep credentials out of browser configuration and Git.

For a new environment, apply migrations, generate registration SQL with `--register-sql /tmp/sources.sql`, review it, and execute it as an operator. The collector cannot register sources or enable/disable them. Changes to configured board URLs also require operator registration before collection. `--sql-output /tmp/import.sql` fetches and validates without writing the database and emits a reviewable import file. A summary reports `persisted: false` in this mode.

## Behavior

- One canonical row per `(source_slug, source_job_id)`; another posting of the same underlying vacancy is not merged automatically. Repeat imports preserve the row ID and first-seen timestamp. Run UUIDs make retries idempotent.
- Raw source JSON, description HTML, source update time, first/last observed timestamps and source identity are retained. HTML is untrusted evidence and must be sanitized before any future display. Missing location/update time stays null. Salary, degree, batch, work mode and employment type are not extracted or confirmed by this adapter.
- All records must validate, IDs must be unique, and `meta.total` must match the response length for a complete run. Malformed rows, missing totals and empty feeds produce partial runs. Empty feeds need review; this slice never automatically closes an entire board.
- Partial runs refresh valid postings but never close missing postings. Failed requests record a failed run without changing jobs. HTTP rate limits do not trigger immediate retries. Run errors contain codes rather than source response bodies or credential-bearing exception strings.
- Only complete nonempty runs close missing postings within the same source. Reappearing postings reopen. A source row lock and observation-time check prevent older imported responses from overwriting newer snapshots.
- Imports are atomic. Each source's fetch/persist is isolated from other sources in normal CLI and dedicated-login runs. Failed database writes are reported with `persisted: false` and a nonzero exit code; a database outage cannot itself be logged to that database. A terminated process before import leaves no run row. These limits matter before scheduling.
- Collection tables are private with RLS. Anonymous and authenticated browser roles have no schema/table/function access. The collector cannot read profiles, edit source configuration, or delete collection records. Public cards, matching, freshness thresholds and scheduling are later slices.

## Verify and inspect

```sh
python3 -m unittest discover -s worker/tests -v
supabase db query --linked --project-ref bqsjlmftpxawctenzvja --file supabase/tests/collection_access.sql
```

The database test runs with scoped roles and rolls back its fixtures. It covers duplicate prevention, idempotent retries, failure/partial safety, source isolation, closure, stale imports, reopening, and browser/collector access restrictions.

An operator can inspect current health without reading personal data:

```sql
select distinct on (source_slug)
  source_slug, started_at, finished_at, outcome, accepted_count, closed_count, errors
from roleping_collection.runs
order by source_slug, started_at desc, finished_at desc;
```

On 2026-10-02, two live imports succeeded: 21 accepted postings per run, 21 distinct stored postings, no closures. Replaying a run was also verified. Security advisors returned no findings after the migration.
