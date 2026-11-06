"""Local commands; keys and raw evidence stay under .local, outside Git."""
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PIN = "351ca8422f7b5b54e80a9c1ce03a222e02415b6b"
UV = ROOT / ".local/uv-tool/bin/uv.exe"
HOST = ROOT / ".local/tools/artemis"
HOST_PYTHON = HOST / ".venv/Scripts/python.exe"
TEST_PYTHON = ROOT / "e2e_test/.venv/Scripts/python.exe"


def run(args, **kwargs):
    return subprocess.run([str(a) for a in args], cwd=ROOT, check=True, **kwargs)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["setup", "host", "check", "run", "collect", "report", "explore"])
    args, rest = parser.parse_known_args()
    if args.command == "setup":
        if not UV.exists():
            run([sys.executable, "-m", "pip", "install", "--target", ROOT / ".local/uv-tool", "uv"])
        if not HOST.exists():
            run(["git", "clone", "https://github.com/google/artemis.git", HOST])
            run(["git", "-C", HOST, "checkout", "--detach", PIN])
        current = subprocess.check_output(["git", "-C", str(HOST), "rev-parse", "HEAD"], text=True).strip()
        if current != PIN:
            raise SystemExit("Existing checkout differs from pin; inspect it before changing versions")
        patch = ROOT / "e2e_test/patches/native-ascii-input.patch"
        applied = subprocess.run(["git", "-C", str(HOST), "apply", "--reverse", "--check", str(patch)], capture_output=True).returncode == 0
        if not applied:
            run(["git", "-C", HOST, "apply", "--check", patch])
            run(["git", "-C", HOST, "apply", patch])
        env = {**os.environ, "UV_CACHE_DIR": str(ROOT / ".local/uv-cache")}
        run([UV, "sync", "--project", HOST, "--python", "3.12", "--frozen", "--no-dev"], env=env)
        run([UV, "sync", "--project", ROOT / "e2e_test", "--python", "3.12", "--frozen"], env=env)
        config = ROOT / ".local/artemis-config.jsonc"
        if not config.exists():
            text = (HOST / "config/artemis.jsonc").read_text(encoding="utf-8")
            text = text.replace('"gemini-3.8-flash"', '"gemini-3.1-flash-lite"').replace('"gemini-3.7-flash"', '"gemini-3.1-flash-lite"').replace('"gemini-3.5-flash-lite"', '"gemini-3.1-flash-lite"')
            config.write_text(text, encoding="utf-8")
        if not (HOST / ".env").exists():
            (HOST / ".env").write_text("GEMINI_API_KEY=\n", encoding="utf-8")
        print("Setup ready. Configure the private .env, then: python e2e_test/manage.py host")
    elif args.command == "host":
        run([HOST_PYTHON, ROOT / "e2e_test/tools/daemon.py"])
    elif args.command == "check":
        raise SystemExit(subprocess.run([str(HOST_PYTHON), str(ROOT / "e2e_test/tools/preflight.py")], cwd=ROOT).returncode)
    elif args.command == "explore":
        run([HOST_PYTHON, ROOT / "e2e_test/tools/explore.py", *rest])
    elif args.command in ("run", "collect"):
        options = ["--live"] if args.command == "run" else ["--collect-only", "-q"]
        # pytest owns failure/skip exit codes; do not turn failures into successful commands.
        result = subprocess.run([str(TEST_PYTHON), "-m", "pytest", "e2e_test", *options, *rest], cwd=ROOT)
        raise SystemExit(result.returncode)
    elif args.command == "report":
        if len(rest) != 1:
            raise SystemExit("report requires one evidence directory")
        sys.path.insert(0, str(ROOT / "e2e_test"))
        from evidence import summarize
        directory = Path(rest[0]).resolve()
        manifest = json.loads((directory / "manifest.json").read_text(encoding="utf-8"))
        rows = summarize(directory, manifest["runs"])
        lines = ["# ARTEMIS execution results", "", "Actual recorded runs only. Blocked is not passed.", "", "| Case | Pass / executed | Blocked | Verdict |", "|---|---|---|---|"]
        lines += [f"| {r['case_id']} | {r['pass_rate']} | {r['blocked']} | {r['verdict']} |" for r in rows]
        lines += ["", "For each row inspect instruction.json, task.json, observed.json, outcome.json, after.png and the original trace. Review private data before sharing."]
        (directory / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(directory / "report.md")


if __name__ == "__main__":
    main()
