"""Save a sanitized readiness report. Never persist raw readiness API responses: they contain keys."""
import json
import hashlib
import os
import subprocess
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

from dotenv import dotenv_values

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / "e2e_test"))
from evidence import available_memory_gb
settings_path = root / ".local/e2e/settings.json"
settings = json.loads(settings_path.read_text(encoding="utf-8")) if settings_path.exists() else {}
device = settings.get("device", "emulator-5556")
adb = str(Path(os.environ["LOCALAPPDATA"]) / "Android/Sdk/platform-tools/adb.exe")
report = {"checked_at": datetime.now(timezone.utc).isoformat(), "device": device, "checks": {}}
checks = report["checks"]
free = available_memory_gb()
report["available_memory_gb"] = round(free, 2) if free is not None else None
checks["host_memory_sufficient"] = free is None or free >= settings.get("minimum_free_memory_gb", 2)
checks["gemini_key_configured"] = bool(dotenv_values(root / ".local/tools/artemis/.env").get("GEMINI_API_KEY"))
try:
    result = subprocess.check_output([adb, "-s", device, "get-state"], timeout=30, text=True).strip()
    checks["device_connected"] = result == "device"
    avd = subprocess.check_output([adb, "-s", device, "emu", "avd", "name"], timeout=30, text=True).splitlines()[0].strip()
    checks["isolated_avd"] = avd == "EVIA_E2E" and device != "emulator-5554"
    user = subprocess.check_output([adb, "-s", device, "shell", "am", "get-current-user"], timeout=30, text=True).strip()
    checks["test_android_user"] = user == str(settings.get("android_user_id"))
    apk = root / "build/app/outputs/flutter-apk/app-debug.apk"
    package_path = subprocess.check_output([adb, "-s", device, "shell", "pm", "path", "com.example.prm393_lab03"], timeout=30, text=True).strip().splitlines()[0].removeprefix("package:")
    if package_path.startswith("/data/app/") and __import__("re").fullmatch(r"[A-Za-z0-9_~=+./-]+", package_path):
        installed_hash = subprocess.check_output([adb, "-s", device, "shell", "sha256sum", package_path], timeout=60, text=True).split()[0]
        with apk.open("rb") as stream:
            workspace_hash = hashlib.file_digest(stream, "sha256").hexdigest()
        report["apk"] = {"workspace_sha256": workspace_hash, "installed_sha256": installed_hash, "same_apk_installed": workspace_hash == installed_hash}
except Exception as error:
    checks["device_connected"] = False
    report["device_error"] = type(error).__name__
try:
    with urllib.request.urlopen(settings.get("base_url", "http://127.0.0.1:8000") + "/api/system/readiness", timeout=120) as response:
        data = json.load(response)
    # Explicit allowlist: upstream auth probe metadata contains unmasked credentials.
    report["host_probes"] = [{"id": p["id"], "status": p["status"], "is_blocker": p["is_blocker"]} for p in data.get("probes", [])]
    checks["host_ready"] = bool(data.get("overall_ready"))
except Exception as error:
    checks["host_ready"] = False
    report["host_error"] = type(error).__name__
checks["dedicated_test_account"] = bool(settings.get("test_account_uid") and settings.get("test_account_email"))
report["ready_for_readonly_smoke"] = all(checks.get(k) for k in ["gemini_key_configured", "device_connected", "isolated_avd", "test_android_user", "host_ready", "host_memory_sufficient"])
destination = root / ".local/e2e/preflight.json"
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report, indent=2))
sys.exit(0 if report["ready_for_readonly_smoke"] else 1)
