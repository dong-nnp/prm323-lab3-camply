import json
from pathlib import Path

import pytest

from cases import CASES
from runner import Session


def pytest_addoption(parser):
    parser.addoption("--live", action="store_true", help="Actually submit paid ARTEMIS tasks")
    parser.addoption("--runs", type=int, default=3)
    parser.addoption("--case", default="", help="Comma-separated IDs, empty selects all")
    parser.addoption("--settings", default=str(Path(__file__).resolve().parents[1] / ".local/e2e/settings.json"))
    parser.addoption("--evidence-dir", default="")


def pytest_generate_tests(metafunc):
    if "case_id" in metafunc.fixturenames:
        selected = metafunc.config.getoption("--case")
        ids = selected.split(",") if selected else list(CASES)
        unknown = set(ids) - CASES.keys()
        if unknown:
            raise pytest.UsageError(f"Unknown cases: {sorted(unknown)}")
        repeats = metafunc.config.getoption("--runs")
        if repeats < 1:
            raise pytest.UsageError("--runs must be >= 1")
        metafunc.parametrize("case_id,repeat", [(c, r) for c in ids for r in range(1, repeats + 1)])


@pytest.fixture(scope="session")
def session(request):
    value = Session(request.config)
    yield value
    value.finish()
