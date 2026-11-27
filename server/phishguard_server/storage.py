"""Simple storage in JSON Lines files (one JSON object per line) under server/var/.

Enough for the project; MongoDB can replace it later without changing the API.
Never stored: the text of a message, except the masked text the user explicitly reports.
"""

import json
import threading
from pathlib import Path
from typing import Any


class JsonlStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        self._lock = threading.Lock()

    def append(self, record: dict[str, Any]) -> None:
        line = json.dumps(record, ensure_ascii=False, default=str)
        with self._lock:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            with self.path.open("a", encoding="utf-8") as f:
                f.write(line + "\n")

    def all(self) -> list[dict[str, Any]]:
        if not self.path.is_file():
            return []
        rows = []
        for line in self.path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    continue  # A half-written line after a crash.
        return rows


class Stores:
    """The three files of the server (SD6: FeedbackRepository and KnownScamRepository)."""

    def __init__(self, data_dir: Path) -> None:
        self.verdicts = JsonlStore(data_dir / "verdicts.jsonl")
        self.feedback = JsonlStore(data_dir / "feedback.jsonl")
        self.scam_candidates = JsonlStore(data_dir / "scam_candidates.jsonl")
