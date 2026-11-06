"""Export selected test evidence with exact secret redaction, never the global DB.

Only TC04 guest screenshots are exported automatically. Other screenshots need a
human privacy review; their originals remain in .local for the final report owner.
"""
import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("directory", type=Path)
args = parser.parse_args()
source = args.directory.resolve()
if not source.is_relative_to(ROOT / ".local/e2e-evidence"):
    raise SystemExit("Only this workspace's private E2E run directories may be exported")
target = ROOT / "evidence/artemis" / source.name
if target.exists():
    raise SystemExit("Export already exists; preserve it and choose another run")
secrets = []
env = ROOT / ".local/tools/artemis/.env"
if env.exists():
    secrets += [line.split("=", 1)[1].strip() for line in env.read_text(encoding="utf-8-sig").splitlines() if "API_KEY=" in line and line.split("=", 1)[1].strip()]
account = ROOT / ".local/e2e/test-account.json"
if account.exists():
    data = json.loads(account.read_text(encoding="utf-8"))
    secrets += [data[k] for k in ("password", "email") if data.get(k)]
allowed = {".json", ".csv", ".md", ".log", ".patch"}
sensitive_cases = set()
for case in source.iterdir():
    if case.is_dir():
        tree = case / "ui-trees.json"
        if not tree.exists() or any(secret in tree.read_text(encoding="utf-8") for secret in secrets):
            sensitive_cases.add(case.name)
copied = {}
for path in source.rglob("*"):
    if not path.is_file():
        continue
    relative = path.relative_to(source)
    guest_image = relative.parts[0].startswith("TC04-run-") and relative.parts[0] not in sensitive_cases and path.suffix.lower() in {".jpg", ".png"}
    if path.suffix not in allowed and not guest_image:
        continue
    if not guest_image and path.suffix.lower() in {".jpg", ".png"}:
        continue
    destination = target / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    if guest_image:
        shutil.copy2(path, destination)
    else:
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        for secret in secrets:
            text = text.replace(secret, "[REDACTED_TEST_SECRET]")
        destination.write_text(text, encoding="utf-8")
    copied[str(relative)] = hashlib.sha256(destination.read_bytes()).hexdigest()
(target / "export-manifest.json").write_text(json.dumps({"source_run": source.name, "redaction": "Exact Gemini key, test email and password removed from text; only guest TC04 images exported automatically", "files_sha256": copied}, indent=2), encoding="utf-8")
print(target)
