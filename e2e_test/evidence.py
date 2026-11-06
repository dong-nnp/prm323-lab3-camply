"""Evidence parsing and reporting shared by pytest and the local runner."""

import csv
import ctypes
import json
import shutil
import sqlite3
from collections import defaultdict
from contextlib import closing
from pathlib import Path


def available_memory_gb():
    import sys
    if sys.platform != "win32":
        return None
    class MemoryStatus(ctypes.Structure):
        _fields_ = [("length", ctypes.c_ulong), ("load", ctypes.c_ulong)] + [(name, ctypes.c_ulonglong) for name in ["total_phys", "available_phys", "total_page", "available_page", "total_virtual", "available_virtual", "extended"]]
    status = MemoryStatus()
    status.length = ctypes.sizeof(status)
    if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(status)):
        raise OSError("Could not read Windows memory status")
    return status.available_phys / 2**30


def parse_output(value, required=()):
    if isinstance(value, str):
        text = value.strip()
        if text.startswith("```json\n") and text.endswith("```"):
            text = text[8:-3].strip()
        try:
            value = json.loads(text)
        except json.JSONDecodeError:
            decoder = json.JSONDecoder()
            candidates = []
            cursor = 0
            while cursor < len(text):
                start = text.find("{", cursor)
                if start < 0:
                    break
                try:
                    candidate, end = decoder.raw_decode(text, start)
                except json.JSONDecodeError:
                    cursor = start + 1
                    continue
                if isinstance(candidate, dict) and (isinstance(candidate.get("observed"), dict) or required and set(required) <= candidate.keys()):
                    candidates.append(candidate)
                cursor = end
            if len(candidates) != 1:
                raise ValueError("Agent report must contain exactly one unambiguous observed JSON object")
            value = candidates[0]
    if isinstance(value, dict) and required and set(required) <= value.keys():
        return value
    if not isinstance(value, dict) or not isinstance(value.get("observed"), dict):
        raise ValueError("Agent must return a JSON object with an observed object")
    return value["observed"]


def check_values(observed, expected, required):
    missing = set(required) - observed.keys()
    assert not missing, f"Missing observed fields: {sorted(missing)}"
    assert expected, "No expected values configured; cannot infer a pass"
    for key, value in expected.items():
        actual = observed.get(key)
        if isinstance(value, dict) and set(value) == {"one_of"}:
            # UI line wrapping may be reported as whitespace or escaped newlines.
            normalize = lambda item: " ".join(item.replace("\\n", "\n").split()) if key == "empty_message" and isinstance(item, str) else item
            assert any(type(actual) is type(option) and normalize(actual) == normalize(option) for option in value["one_of"]), f"{key}: expected one of {value['one_of']!r}, observed {actual!r}"
            continue
        assert type(actual) is type(value) and actual == value, f"{key}: expected {value!r}, observed {actual!r}"


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")


def collect_trace(traces, task_id, target):
    """Pinned Flash host persists its final report in DataEngine, not SDK.output."""
    traces, target = Path(traces), Path(target)
    database = traces / "data_engine.db"
    if not database.exists():
        return None
    with closing(sqlite3.connect(database.as_uri() + "?mode=ro", uri=True)) as connection:
        connection.row_factory = sqlite3.Row
        rows = connection.execute(
            "SELECT step_number,timestamp,action_taken,summary,pre_image_name,post_image_name,last_execution_result FROM steps WHERE session_id=? ORDER BY step_number",
            (task_id,),
        ).fetchall()
        steps = [dict(row) for row in rows]
        images = {}
        final = None
        for step in steps:
            action = json.loads(step["action_taken"] or "{}")
            step["action_taken"] = action
            if action.get("action") == "report_task_status":
                final = action.get("args", {}).get("explanation")
            for name in (step["pre_image_name"], step["post_image_name"]):
                if not name or name in images:
                    continue
                row = connection.execute("SELECT image_name,ui_tree FROM images WHERE image_name=?", (name,)).fetchone()
                if row:
                    images[name] = dict(row)
                    for suffix in (".jpg", ".png"):
                        image = traces / "images" / (name + suffix)
                        if image.is_file():
                            (target / "screens").mkdir(parents=True, exist_ok=True)
                            shutil.copy2(image, target / "screens" / image.name)
        write_json(target / "steps.json", steps)
        write_json(target / "ui-trees.json", images)
        write_json(target / "final-report.json", {"explanation": final, "source": "original ARTEMIS DataEngine report_task_status"})
        return final


def check_empty_search_trace(target):
    """Independently reject the agent confusing clipboard/history with search results."""
    target = Path(target)
    images = json.loads((target / "ui-trees.json").read_text(encoding="utf-8"))
    steps = json.loads((target / "steps.json").read_text(encoding="utf-8"))
    snapshots = []
    for step in steps:
        for name in (step["pre_image_name"], step["post_image_name"]):
            tree = images.get(name, {}).get("ui_tree")
            if tree:
                snapshots.append(json.loads(tree) if isinstance(tree, str) else tree)
    assert snapshots, "No original UI trees for search verification"
    assert any(any(item.get("class") == "android.widget.EditText" and "EVIA_NO_MATCH_6f0a9dc2" in (item.get("text", "") + item.get("content-desc", "")) for item in tree) for tree in snapshots), "Nonce was not observed inside the search field"
    assert any(any("No events found" in item.get("content-desc", "") + item.get("text", "") for item in tree) for tree in snapshots), "Empty search result was not observed in the original UI tree"
    final = "\n".join(item.get("content-desc", "") + item.get("text", "") for item in snapshots[-1])
    assert "Suggested Events" in final and "Clear search" not in final, "Final UI does not prove the query was cleared and suggestions restored"


def summarize(directory, planned_runs=3):
    directory = Path(directory)
    groups = defaultdict(list)
    for path in directory.glob("*/outcome.json"):
        row = json.loads(path.read_text(encoding="utf-8"))
        groups[row["case_id"]].append(row)
    rows = []
    for case_id, runs in sorted(groups.items()):
        passed = sum(r["status"] == "passed" for r in runs)
        executed = sum(r["status"] in ("passed", "failed") for r in runs)
        rows.append({
            "case_id": case_id, "planned_runs": planned_runs, "attempts": len(runs),
            "passed": passed, "failed": sum(r["status"] == "failed" for r in runs),
            "blocked": sum(r["status"] == "blocked" for r in runs),
            "executed": executed, "pass_rate": f"{passed}/{executed}" if executed else "not_run",
            "average_seconds": round(sum(r.get("seconds", 0) for r in runs) / len(runs), 2),
            "verdict": "passed_required_runs" if planned_runs >= 3 and passed == planned_runs == len(runs) else "incomplete_or_unstable",
            "reasons": " | ".join(dict.fromkeys(r.get("reason", "") for r in runs if r.get("reason"))),
        })
    with (directory / "results.csv").open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]) if rows else ["case_id"])
        writer.writeheader()
        writer.writerows(rows)
    write_json(directory / "summary.json", {"planned_runs": planned_runs, "cases": rows})
    return rows
