"""Settings read from environment variables or server/.env (never committed)."""

import os
from dataclasses import dataclass
from pathlib import Path

ENV_FILE = Path(__file__).resolve().parents[1] / ".env"


def _read_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.is_file():
        return values
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


@dataclass(frozen=True)
class Settings:
    safe_browsing_key: str = ""
    virustotal_key: str = ""
    llm_provider: str = "gemini"  # gemini or groq (free), anthropic or openai
    llm_api_key: str = ""
    llm_model: str = ""  # Empty: the provider's default model (see analysis/llm.py).
    # The app gives up after 8 s, so the server answers within this budget.
    total_budget: float = 7.3
    # Each external call stops after this many seconds.
    http_timeout: float = 3.5
    # Link and domain checks stop after this many seconds; the rest is for the AI.
    checks_timeout: float = 5.0
    # Where verdicts, feedback and reported scams are saved (JSON Lines files).
    data_dir: Path = Path(__file__).resolve().parents[1] / "var"

    @classmethod
    def load(cls, env_file: Path = ENV_FILE) -> "Settings":
        file_values = _read_env_file(env_file)

        def get(name: str) -> str:
            return os.environ.get(name) or file_values.get(name, "")

        data_dir = get("DATA_DIR")
        return cls(
            data_dir=Path(data_dir) if data_dir else cls.data_dir,
            safe_browsing_key=get("GOOGLE_SAFE_BROWSING_API_KEY"),
            virustotal_key=get("VIRUSTOTAL_API_KEY"),
            llm_provider=get("LLM_PROVIDER") or "gemini",
            llm_api_key=get("LLM_API_KEY"),
            llm_model=get("LLM_MODEL"),
        )
