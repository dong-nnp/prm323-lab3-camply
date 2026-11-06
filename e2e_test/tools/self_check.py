"""Offline checks of grading/evidence logic, NOT ARTEMIS execution evidence."""
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from cases import CASES
from evidence import check_empty_search_trace, check_values, collect_trace, parse_output, summarize, write_json


class EvidenceTests(unittest.TestCase):
    def test_success_without_observations_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_output({"status": "SUCCESS"})
        with self.assertRaises(AssertionError):
            check_values({"count": True}, {"count": 1}, ["count"])
        with self.assertRaises(AssertionError):
            check_values({}, {"count": 1}, ["count"])

    def test_observed_values_must_match(self):
        actual = parse_output('```json\n{"observed":{"count":2}}\n```')
        check_values(actual, {"count": 2}, ["count"])
        with self.assertRaises(AssertionError):
            check_values(actual, {"count": 3}, ["count"])
        self.assertEqual(parse_output('{"count":2}', ["count"]), actual)
        self.assertEqual(parse_output('Done. {"observed":{"count":2}}'), actual)
        with self.assertRaises(ValueError):
            parse_output('{"observed":{"count":2}} {"observed":{"count":3}}')
        check_values({"empty_message": "No events found\\nNo results."}, {"empty_message": {"one_of": ["No events found\nNo results."]}}, ["empty_message"])
        expected = {"message": {"one_of": ["No events found", "No events found. Empty results."]}}
        check_values({"message": "No events found. Empty results."}, expected, ["message"])
        with self.assertRaises(AssertionError):
            check_values({"message": "Suggested Events"}, expected, ["message"])

    def test_blocked_does_not_inflate_pass_rate(self):
        with tempfile.TemporaryDirectory() as folder:
            for index, status in enumerate(["passed", "failed", "blocked"]):
                write_json(Path(folder) / str(index) / "outcome.json", {"case_id": "TC04", "status": status, "seconds": 2})
            row = summarize(folder)[0]
            self.assertEqual(row["pass_rate"], "1/2")
            self.assertEqual(row["blocked"], 1)
            self.assertNotEqual(row["verdict"], "passed_3_of_3")

    def test_suite_covers_all_planned_variants(self):
        self.assertEqual(len(CASES), 20)
        self.assertEqual(sum(c.native for c in CASES.values()), 6)
        self.assertNotIn("TC03", CASES)

    def test_one_successful_smoke_is_not_three_completed_runs(self):
        with tempfile.TemporaryDirectory() as folder:
            write_json(Path(folder) / "run-1/outcome.json", {"case_id": "TC04", "status": "passed", "seconds": 1})
            self.assertEqual(summarize(folder, planned_runs=1)[0]["verdict"], "incomplete_or_unstable")

    def test_trace_export_reads_only_requested_session(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            with sqlite3.connect(root / "data_engine.db") as connection:
                connection.execute("CREATE TABLE steps (session_id,step_number,timestamp,action_taken,summary,pre_image_name,post_image_name,last_execution_result)")
                connection.execute("CREATE TABLE images (image_name,ui_tree)")
                for sid, count in [("selected", 0), ("unrelated", 99)]:
                    action = {"action": "report_task_status", "args": {"explanation": json.dumps({"observed": {"count": count}})}}
                    connection.execute("INSERT INTO steps VALUES (?,?,?,?,?,?,?,?)", (sid, 1, 0, json.dumps(action), None, None, None, None))
            connection.close()
            output = collect_trace(root, "selected", root / "export")
            self.assertEqual(parse_output(output), {"count": 0})
            steps = json.loads((root / "export/steps.json").read_text())
            self.assertEqual(len(steps), 1)

    def test_clipboard_and_inferred_recovery_cannot_pass(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            images = {
                "typed": {"ui_tree": [{"class": "android.widget.EditText", "text": "EVIA_NO_MATCH_6f0a9dc2"}]},
                "empty": {"ui_tree": [{"content-desc": "No events found"}]},
                "restored": {"ui_tree": [{"content-desc": "Suggested Events"}]},
            }
            write_json(root / "ui-trees.json", images)
            write_json(root / "steps.json", [{"pre_image_name": key, "post_image_name": None} for key in images])
            check_empty_search_trace(root)
            images["typed"]["ui_tree"][0]["class"] = "android.widget.TextView"
            write_json(root / "ui-trees.json", images)
            with self.assertRaisesRegex(AssertionError, "search field"):
                check_empty_search_trace(root)


if __name__ == "__main__":
    unittest.main()
