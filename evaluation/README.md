# Cohort source-fit evaluation

Use this small, dependency-free harness for Sprint 1's manually reviewed sample. It does not collect jobs or infer eligibility. Profiles may be synthetic while the workflow is developed; label them as such and never present synthetic cases as demand evidence.

Prepare three CSV files with these headers:

- `profiles.csv`: `profile_id,case_type,role_family,location,notes` (`case_type` is `consented` or `synthetic`). Keep personal names, email addresses, and resumes out of this folder.
- `jobs.csv`: `job_id,source_id,source_url,employer,role_title,observed_at,run_outcome`. Use stable IDs. Record source outcome separately from whether a particular job is eligible.
- `judgments.csv`: `profile_id,job_id,label,rank,in_reference_set,reason`. `label` is `eligible`, `ineligible`, or `uncertain`. `rank` is the proposed shortlist position, or blank for a job not recommended. `in_reference_set` is `yes` or `no`; the reference set is independently assembled from the same collection window. Explain eligibility decisions in `reason`.

Run `python3 tools/evaluate_cohort.py profiles.csv jobs.csv judgments.csv --output report.json` from the repository root. The report includes precision among positions 1–5, reference-set coverage, zero-match fraction, and per-profile supply. A null metric means its denominator is zero. Review both accepted and rejected jobs; the script cannot establish that labels, source rights, job status, or opportunity supply are correct.

Keep real evaluation inputs and dated reports in a separate dated evidence directory after obtaining the required cohort/source permissions. Do not alter the historical benchmark under `evidence/job-scraping-benchmark`.
