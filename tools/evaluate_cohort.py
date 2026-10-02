"""Evaluate manually adjudicated cohort shortlists from CSV files.

This tool intentionally consumes reviewed labels rather than guessing eligibility.
Run: python3 tools/evaluate_cohort.py profiles.csv jobs.csv judgments.csv
"""

import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path


def read_rows(path, required):
    with Path(path).open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames or not set(required).issubset(reader.fieldnames):
            raise ValueError(f"{path}: required columns: {', '.join(required)}")
        rows = list(reader)
        if any(None in row for row in rows):
            raise ValueError(f"{path}: row has more fields than the header")
    return rows


def evaluate(profiles, jobs, judgments):
    profile_ids = {row["profile_id"] for row in profiles}
    job_ids = {row["job_id"] for row in jobs}
    if len(profile_ids) != len(profiles) or "" in profile_ids:
        raise ValueError("profile_id must be unique and nonempty")
    if len(job_ids) != len(jobs) or "" in job_ids:
        raise ValueError("job_id must be unique and nonempty")

    by_profile = defaultdict(list)
    seen = set()
    for row in judgments:
        profile_id, job_id = row["profile_id"], row["job_id"]
        if profile_id not in profile_ids or job_id not in job_ids:
            raise ValueError(f"unknown profile/job pair: {profile_id}/{job_id}")
        if (profile_id, job_id) in seen:
            raise ValueError(f"duplicate judgment: {profile_id}/{job_id}")
        seen.add((profile_id, job_id))
        if row["label"] not in {"eligible", "ineligible", "uncertain"}:
            raise ValueError(f"invalid label for {profile_id}/{job_id}")
        if row["in_reference_set"] not in {"yes", "no"}:
            raise ValueError(f"invalid reference-set flag for {profile_id}/{job_id}")
        if not row.get("reason", "").strip():
            raise ValueError(f"missing review reason for {profile_id}/{job_id}")
        rank = row["rank"]
        if rank:
            if not rank.isdecimal() or int(rank) < 1:
                raise ValueError(f"invalid rank for {profile_id}/{job_id}")
            row = {**row, "rank": int(rank)}
        by_profile[profile_id].append(row)

    result = []
    total_recommended = total_eligible = total_reference = total_found = 0
    for profile_id in sorted(profile_ids):
        rows = by_profile[profile_id]
        ranked = [row for row in rows if row["rank"]]
        ranks = [row["rank"] for row in ranked]
        if sorted(ranks) != list(range(1, len(ranks) + 1)):
            raise ValueError(f"ranks must be unique and consecutive for {profile_id}")
        top = [row for row in ranked if row["rank"] <= 5]
        eligible = sum(row["label"] == "eligible" for row in top)
        reference = sum(row["label"] == "eligible" and row["in_reference_set"] == "yes" for row in rows)
        found = sum(row["label"] == "eligible" and row["in_reference_set"] == "yes" for row in ranked)
        total_recommended += len(top)
        total_eligible += eligible
        total_reference += reference
        total_found += found
        result.append({"profile_id": profile_id, "top_five_count": len(top),
                       "top_five_precision": eligible / len(top) if top else None,
                       "reference_eligible_count": reference,
                       "reference_coverage": found / reference if reference else None,
                       "uncertain_in_top_five": sum(row["label"] == "uncertain" for row in top)})

    return {"profiles": result, "summary": {
        "profile_count": len(profile_ids),
        "zero_match_fraction": sum(row["top_five_count"] == 0 for row in result) / len(result) if result else None,
        "top_five_precision": total_eligible / total_recommended if total_recommended else None,
        "reference_coverage": total_found / total_reference if total_reference else None,
        "recommended_count": total_recommended,
        "reference_eligible_count": total_reference,
        "label_counts": dict(Counter(row["label"] for row in judgments)),
    }}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("profiles")
    parser.add_argument("jobs")
    parser.add_argument("judgments")
    parser.add_argument("--output", help="Write JSON report to this path")
    args = parser.parse_args()
    report = evaluate(
        read_rows(args.profiles, ["profile_id"]),
        read_rows(args.jobs, ["job_id", "source_id", "source_url"]),
        read_rows(args.judgments, ["profile_id", "job_id", "label", "rank", "in_reference_set", "reason"]),
    )
    output = json.dumps(report, indent=2) + "\n"
    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
    else:
        print(output, end="")


if __name__ == "__main__":
    main()
