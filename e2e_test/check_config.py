"""Offline compatibility check against the installed Artemis config loaders."""

from artemis.config.agent import load_agent_config
from artemis.config.llm import parse_llm_config
from types import SimpleNamespace
from unittest.mock import patch

from artemis.agents.flash import runner as flash_runner


def check_models(value):
    if isinstance(value, dict):
        if "provider" in value:
            assert value["provider"] == "openai", value
            assert value["model"] == "deepseek-flash", value
        for child in value.values():
            check_models(child)
    elif isinstance(value, list):
        for child in value:
            check_models(child)


if __name__ == "__main__":
    config = parse_llm_config()
    check_models(config.model_dump())
    assert load_agent_config().flash.max_turns == 20
    # Construct the real runner so Gemini-only background services cannot slip in.
    with (
        patch.object(flash_runner, "UnifiedMobileController"),
        patch.object(flash_runner, "McpActionExecutor"),
        patch.object(
            flash_runner,
            "VisualStepSummarizer",
            side_effect=AssertionError("DeepSeek smoke must not start the Gemini summarizer"),
        ),
    ):
        runner = flash_runner.FlashRunner(SimpleNamespace(), goal="Offline config check")
        assert runner.summarizer is None
    print("PASS: DeepSeek routing, 20-turn limit and Flash startup without Gemini.")
