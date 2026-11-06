import asyncio
import hashlib
import json
import os
import shutil
import subprocess
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

import pytest
from artemis_client import ArtemisClient
from artemis_client.errors import ConflictError, TaskRejectedError

from cases import CASES
from evidence import available_memory_gb, check_empty_search_trace, check_values, collect_trace, parse_output, summarize, write_json

ROOT = Path(__file__).resolve().parents[1]
ARTEMIS_SHA = "351ca8422f7b5b54e80a9c1ce03a222e02415b6b"


def command(args, *, timeout=90):
    result = subprocess.run(args, cwd=ROOT, capture_output=True, timeout=timeout, check=True)
    return result.stdout


class Session:
    def __init__(self, config):
        self.config = config
        self.settings_path = Path(config.getoption("--settings"))
        self.settings = json.loads(self.settings_path.read_text(encoding="utf-8")) if self.settings_path.exists() else {}
        run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
        self.directory = Path(config.getoption("--evidence-dir") or ROOT / ".local/e2e-evidence" / run_id)
        self.directory.mkdir(parents=True, exist_ok=False)
        self.device = self.settings.get("device", "emulator-5554")
        self.adb = self.settings.get("adb") or shutil.which("adb") or str(Path(os.environ.get("LOCALAPPDATA", "")) / "Android/Sdk/platform-tools/adb.exe")
        self.client = ArtemisClient(self.settings.get("base_url", "http://127.0.0.1:8000"), device_serial=self.device, request_timeout=120)
        self.sdk_checkout = ROOT / ".local/tools/artemis"
        self.traces = ROOT / ".local/artemis-traces"
        manifest = {"started_at": run_id, "artemis_commit": ARTEMIS_SHA, "profile": "flash", "model": self.settings.get("model", "gemini-2.5-flash"), "device": self.device, "runs": config.getoption("--runs"), "command": __import__("sys").argv, "evidence_contains_private_test_data": True, "host_customization": "UIAutomator backend; real lock-state probe timeout 15s"}
        try:
            manifest["app_commit"] = command(["git", "rev-parse", "HEAD"]).decode().strip()
            manifest["working_tree"] = command(["git", "status", "--short"]).decode(errors="replace")
            sdk_diff = command(["git", "-C", str(self.sdk_checkout), "diff"])
            manifest["artemis_patch_sha256"] = hashlib.sha256(sdk_diff).hexdigest()
            (self.directory / "artemis-local.patch").write_bytes(sdk_diff)
            apk = ROOT / "build/app/outputs/flutter-apk/app-debug.apk"
            if apk.exists():
                manifest["workspace_apk_sha256"] = hashlib.file_digest(apk.open("rb"), "sha256").hexdigest()
                manifest["apk_identity_note"] = "Hash of workspace APK; does not prove the same APK is installed"
        except Exception as error:
            manifest["metadata_error"] = type(error).__name__
        write_json(self.directory / "manifest.json", manifest)
        print(f"Evidence: {self.directory}")

    def block(self, reason):
        pytest.skip(reason)

    def fixture(self, case, target):
        entry = self.settings.get("cases", {}).get(case.id, {})
        if not case.fixture:
            return entry
        if not self.settings.get("test_account_uid") or not self.settings.get("test_account_email"):
            self.block("Dedicated test account UID/email is not configured; refusing to use the current app account")
        hook = entry.get("prepare_command")
        if not isinstance(hook, list) or not hook or not all(isinstance(arg, str) for arg in hook):
            self.block(f"{case.id}: missing independent fixture/reset prepare_command")
        if not isinstance(entry.get("verify_command"), list) or not entry["verify_command"]:
            self.block(f"{case.id}: missing backend verification command; refusing to submit task")
        # Local hooks are maintainer-controlled argv arrays, never agent-generated shell commands.
        before = json.loads(command(hook + [case.id], timeout=180).decode("utf-8-sig"))
        if before.get("case_id") != case.id or before.get("uid") != self.settings["test_account_uid"] or before.get("ready") is not True:
            self.block("Fixture reset did not confirm the configured test UID and case")
        if not isinstance(before.get("expected"), dict):
            self.block("Fixture driver must return server-derived expected values")
        write_json(target / "fixture-before.json", before)
        return {**entry, "expected": before["expected"], "context": before.get("context", {})}

    def execute(self, case_id, repeat):
        case = CASES[case_id]
        target = self.directory / f"{case_id}-run-{repeat}"
        target.mkdir()
        start = time.monotonic()
        outcome = {"case_id": case_id, "repeat": repeat, "status": "blocked"}
        task_id = None
        completed = False
        entry = {}
        try:
            if not self.config.getoption("--live"):
                self.block("Live execution disabled; use --live after configuring the test environment")
            if case_id in self.settings.get("deferred_cases", []):
                self.block(f"{case_id}: explicitly deferred in local settings; no task submitted")
            free_memory = available_memory_gb()
            outcome["available_memory_gb_before"] = round(free_memory, 2) if free_memory is not None else None
            if free_memory is not None and free_memory < self.settings.get("minimum_free_memory_gb", 2):
                self.block(f"Host has only {free_memory:.2f} GB free RAM; close unused apps before live E2E")
            android_user = self.settings.get("android_user_id")
            if not isinstance(android_user, int) or android_user < 0:
                self.block("Configure the isolated Android test user before sending screens to the model")
            if android_user == 0:
                expected_avd = self.settings.get("avd_name")
                if expected_avd != "EVIA_E2E" or self.device == "emulator-5554":
                    self.block("Owner user is allowed only on the separate EVIA_E2E emulator")
                actual_avd = command([self.adb, "-s", self.device, "emu", "avd", "name"]).decode().splitlines()[0].strip()
                if actual_avd != expected_avd:
                    self.block("Device is not the separate EVIA_E2E AVD")
            current_user = command([self.adb, "-s", self.device, "shell", "am", "get-current-user"]).decode().strip()
            if current_user != str(android_user):
                self.block("Device is not on the isolated test user; no task submitted")
            if command(["git", "-C", str(self.sdk_checkout), "rev-parse", "HEAD"]).decode().strip() != ARTEMIS_SHA:
                self.block("ARTEMIS checkout differs from the pinned commit")
            entry = self.fixture(case, target)
            expected = {**case.expected, **entry.get("expected", {})}
            if not set(case.fields) <= expected.keys():
                self.block("Expected values missing: " + ", ".join(sorted(set(case.fields) - expected.keys())))
            instruction = (
                "Test EVIA Android app com.example.prm393_lab03. " + case.steps
                + "\nTest setup (private test data): " + json.dumps(entry.get("context", {}), ensure_ascii=False)
                + "\nDo not use personal accounts or debug demo attendance. Stop if a prerequisite is not met. "
                + "Return ONLY JSON {\"observed\": {...}} with these fields: " + ", ".join(case.fields)
                + ". Report only values you actually read or actions you performed. Use null for unobservable values. Never infer success from the requested goal."
                + '\nFLASH OUTPUT CONTRACT: put the exact JSON {"observed": {...}} inside the explanation argument of your final report_task_status tool call. Perform every requested step before reporting completion. If a step fails or is not observed, use null/false and report failure; do not say it would likely work.'
            )
            write_json(target / "instruction.json", {"instruction": instruction, "expected": expected})
            if case.analytics:
                command([self.adb, "-s", self.device, "shell", "setprop", "debug.firebase.analytics.app", "com.example.prm393_lab03"])
            log_start = command([self.adb, "-s", self.device, "shell", "date", "+%m-%dT%H:%M:%S.000"]).decode().strip().replace("T", " ")
            async def run():
                nonlocal task_id
                await self.client.health()
                handle = await self.client.submit(instruction, profile="flash", device_serial=self.device,
                    locked_app_package=None if case.native else "com.example.prm393_lab03",
                    enable_outputter=False)
                task_id = handle.task_id
                write_json(target / "task.json", {"task_id": task_id, "replay_url": f"http://127.0.0.1:8000", "status": handle.status})
                return await self.client.wait_for_task(task_id, timeout=self.settings.get("timeout_seconds", 600))
            result = asyncio.run(run())
            completed = result.done
            write_json(target / "agent-result.json", dict(result.raw))
            outcome["task_id"] = task_id
            assert result.succeeded, f"ARTEMIS task ended {result.status}"
            output = result.output
            final_report = collect_trace(self.traces, task_id, target)
            if output is None:
                output = final_report
            trace = self.traces / task_id
            if output is None and trace.exists():
                status_file = trace / "status.json"
                if status_file.exists():
                    output = json.loads(status_file.read_text(encoding="utf-8")).get("result")
            observed = parse_output(output, case.fields)
            write_json(target / "observed.json", observed)
            check_values(observed, expected, case.fields)
            if case_id == "TC04":
                check_empty_search_trace(target)
            if case.native:
                assert trace.exists(), "Native interaction requires original ARTEMIS trace for review"
            if case.analytics:
                log = command([self.adb, "-s", self.device, "logcat", "-d", "-T", log_start, "-s", "FA:V", "FA-SVC:V"]).decode(errors="replace")
                (target / "analytics-logcat.txt").write_text(log, encoding="utf-8")
                assert "search" in log and ("Logging event" in log or "Logging event (FE)" in log), "No search Analytics log evidence for this run"
            if case.fixture:
                verify = entry.get("verify_command")
                if not isinstance(verify, list) or not verify:
                    self.block("Missing post-run backend verification hook; UI alone cannot prove server invariants")
                after = json.loads(command(verify + [case_id], timeout=180).decode("utf-8-sig"))
                write_json(target / "fixture-after.json", after)
                assert after.get("uid") == self.settings["test_account_uid"] and after.get("case_id") == case_id and after.get("verified") is True
            outcome["status"] = "passed"
        except (ConflictError, TaskRejectedError) as error:
            outcome["reason"] = str(error)
            pytest.skip(str(error))
        except pytest.skip.Exception as error:
            outcome["reason"] = str(error)
            raise
        except BaseException as error:
            outcome["status"] = "failed"
            outcome["reason"] = str(error) if isinstance(error, (AssertionError, ValueError)) else type(error).__name__
            raise
        finally:
            if task_id:
                # Stop timed-out/running work before the next case can touch the same device.
                if not completed:
                    try:
                        asyncio.run(self.client.stop(task_id))
                    except Exception:
                        outcome["stop_warning"] = "Could not confirm task stopped; inspect daemon before continuing"
                try:
                    (target / "after.png").write_bytes(command([self.adb, "-s", self.device, "exec-out", "screencap", "-p"]))
                except Exception:
                    outcome["screenshot_warning"] = "Capture failed"
                trace = self.traces / task_id
                try:
                    collect_trace(self.traces, task_id, target)
                except Exception:
                    outcome["trace_warning"] = "Could not export DataEngine steps/images"
                if trace.is_dir():
                    shutil.copytree(trace, target / "trace", dirs_exist_ok=True)
                cleanup = entry.get("cleanup_command")
                if cleanup:
                    try:
                        cleaned = json.loads(command(cleanup + [case_id], timeout=180).decode("utf-8-sig"))
                        write_json(target / "cleanup.json", cleaned)
                        assert cleaned.get("cleaned") is True
                    except Exception:
                        outcome["cleanup_warning"] = "Fixture cleanup failed; inspect isolated test data before retrying"
                        if outcome["status"] == "passed":
                            outcome["status"] = "failed"
                            outcome["reason"] = "Post-run cleanup did not restore fixture"
            outcome["seconds"] = round(time.monotonic() - start, 3)
            write_json(target / "outcome.json", outcome)
            if outcome.get("reason") == "Post-run cleanup did not restore fixture":
                raise AssertionError(outcome["reason"])

    def finish(self):
        summarize(self.directory, self.config.getoption("--runs"))
