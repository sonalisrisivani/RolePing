import unittest

from evaluate_cohort import evaluate


class EvaluateCohortTests(unittest.TestCase):
    def setUp(self):
        self.profiles = [{"profile_id": "p1"}, {"profile_id": "p2"}]
        self.jobs = [{"job_id": "j1"}, {"job_id": "j2"}]
        self.judgments = [
            {"profile_id": "p1", "job_id": "j1", "label": "eligible", "rank": "1", "in_reference_set": "yes", "reason": "reviewed"},
            {"profile_id": "p1", "job_id": "j2", "label": "ineligible", "rank": "2", "in_reference_set": "no", "reason": "reviewed"},
        ]

    def test_reports_precision_coverage_and_zero_supply(self):
        summary = evaluate(self.profiles, self.jobs, self.judgments)["summary"]
        self.assertEqual(summary["top_five_precision"], 0.5)
        self.assertEqual(summary["reference_coverage"], 1.0)
        self.assertEqual(summary["zero_match_fraction"], 0.5)

    def test_rejects_rank_gap(self):
        self.judgments[0]["rank"] = "2"
        self.judgments[1]["rank"] = "3"
        with self.assertRaisesRegex(ValueError, "consecutive"):
            evaluate(self.profiles, self.jobs, self.judgments)

    def test_rejects_duplicate_review(self):
        with self.assertRaisesRegex(ValueError, "duplicate judgment"):
            evaluate(self.profiles, self.jobs, self.judgments * 2)


if __name__ == "__main__":
    unittest.main()
