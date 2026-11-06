"""Pro exploration recorder; execution completion is never automatic issue-review approval."""
import asyncio
import json
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "e2e_test"))
from artemis_client import ArtemisClient
from evidence import available_memory_gb, collect_trace, write_json
from runner import command

minutes = int(sys.argv[1]) if len(sys.argv) > 1 else 15
if not 15 <= minutes <= 30:
    raise SystemExit("Exploratory session must be 15–30 minutes")
settings = json.loads((ROOT / ".local/e2e/settings.json").read_text(encoding="utf-8"))
free = available_memory_gb()
if free is not None and free < settings.get("minimum_free_memory_gb", 2):
    raise SystemExit("Insufficient free RAM for a meaningful exploration; no task submitted")
if settings.get("avd_name") != "EVIA_E2E" or settings.get("device") != "emulator-5556":
    raise SystemExit("Configure isolated EVIA_E2E device first")
adb = str(Path(__import__("os").environ["LOCALAPPDATA"]) / "Android/Sdk/platform-tools/adb.exe")
if command([adb, "-s", settings["device"], "emu", "avd", "name"]).decode().splitlines()[0].strip() != "EVIA_E2E":
    raise SystemExit("Unexpected AVD; no screens sent")
run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-pro-" + uuid.uuid4().hex[:8]
target = ROOT / ".local/e2e-evidence" / run_id
target.mkdir(parents=True)
goal = (
    f"Explore EVIA Android com.example.prm393_lab03 for at least {minutes} minutes. "
    "This is an unscripted exploratory session on a dedicated blank test AVD. Use Guest if not signed in. "
    "Investigate navigation/Back, Search, categories/filters, scrolling, event About/Schedule/Location and keyboard layout. "
    "Choose the next action based on observations, revisit suspected issues and record reproduction steps. "
    "Do not sign into a personal account, register/cancel events, claim daily, redeem rewards, press demo attendance, "
    "change Remote Config, force a crash, or leave network/device settings modified. "
    "Report only reproducible observations and actual screen values. A task finishing early is not a completed 15-minute session."
)
write_json(target / "manifest.json", {"profile": "pro", "model": settings.get("model"), "device": settings["device"], "requested_minutes": minutes, "runs": 1, "command": sys.argv, "charter": goal})


async def main():
    client = ArtemisClient(settings.get("base_url"), request_timeout=120)
    task_id = None
    start = time.monotonic()
    report = {"status": "not_completed", "requested_minutes": minutes}
    try:
        handle = await client.submit(goal, profile="pro", device_serial=settings["device"], explorer_mode="pro", verification_level="checkpoints", enable_outputter=True)
        task_id = handle.task_id
        write_json(target / "task.json", {"task_id": task_id})
        result = await client.wait_for_task(task_id, timeout=minutes * 60 + 120)
        write_json(target / "agent-result.json", dict(result.raw))
        collect_trace(ROOT / ".local/artemis-traces", task_id, target)
        steps = json.loads((target / "steps.json").read_text())
        span = steps[-1]["timestamp"] - steps[0]["timestamp"] if len(steps) > 1 else 0
        report.update({"task_id": task_id, "task_status": result.status, "step_count": len(steps), "active_step_span_seconds": span, "status": "awaiting_human_issue_review" if result.succeeded and span >= minutes * 60 else "incomplete_duration_or_task_failure"})
    finally:
        if task_id:
            current = await client.get_task(task_id)
            if not current.done:
                await client.stop(task_id)
        report["wall_seconds"] = time.monotonic() - start
        write_json(target / "exploratory-status.json", report)
        (target / "exploratory.md").write_text("# Exploratory session review\n\nExecution metadata: exploratory-status.json.\nReview the original trace before claiming findings.\n\n| Issue | Observed behavior | Reproduction steps | Step/Screen evidence | Severity |\n|---|---|---|---|---|\n\nStatus: issue review not performed by this recorder.\n", encoding="utf-8")
        print(target)


asyncio.run(main())
