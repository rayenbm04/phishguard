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
    # Each external call stops after this many seconds (the app gives up after 8 s).
    http_timeout: float = 3.5
    # The whole set of checks stops after this many seconds.
    checks_timeout: float = 6.5

    @classmethod
    def load(cls, env_file: Path = ENV_FILE) -> "Settings":
        file_values = _read_env_file(env_file)

        def get(name: str) -> str:
            return os.environ.get(name) or file_values.get(name, "")

        return cls(
            safe_browsing_key=get("GOOGLE_SAFE_BROWSING_API_KEY"),
            virustotal_key=get("VIRUSTOTAL_API_KEY"),
        )
