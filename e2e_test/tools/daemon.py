"""Run the pinned local host without changing global IDE/MCP settings."""
import os
import runpy
import sys
from pathlib import Path

from dotenv import dotenv_values

root = Path(__file__).resolve().parents[2]
checkout = root / ".local/tools/artemis"
for key, value in dotenv_values(checkout / ".env").items():
    if value:
        os.environ[key] = value
os.environ["ARTEMIS_ARTEMIS_JSONC"] = str(root / ".local/artemis-config.jsonc")
os.environ["ARTEMIS_APP_DIR"] = str(root / ".local/artemis-state")
os.environ["ARTEMIS_TRACES_DIR"] = str(root / ".local/artemis-traces")
os.environ["PYTHONUTF8"] = "1"
os.environ["ARTEMIS_HIERARCHY_BACKEND"] = "uiautomator"
os.environ["ARTEMIS_HELPER_AUTO_INSTALL"] = "false"
adb_dir = Path(os.environ["LOCALAPPDATA"]) / "Android/Sdk/platform-tools"
os.environ["PATH"] = str(adb_dir) + os.pathsep + os.environ.get("PATH", "")
os.chdir(checkout)
sys.path.insert(0, str(checkout))
# Windows ADB dumpsys measured ~5s here; retain the real lock check, allow 15s.
from artemis.core.diagnostics.probes.adb_probe import AdbDeviceProbe

_original_lock_probe = AdbDeviceProbe._get_confirmed_device_lock_state


async def _bounded_lock_probe(self, adb_path, serial, timeout_seconds=2.0):
    return await _original_lock_probe(self, adb_path, serial, timeout_seconds=max(15.0, timeout_seconds))


AdbDeviceProbe._get_confirmed_device_lock_state = _bounded_lock_probe
sys.argv = ["artemis-server", "--host", "127.0.0.1", "--port", "8000"]
runpy.run_module("apps.admin_console.server", run_name="__main__")
