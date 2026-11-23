"""KnownScamMatcher (SD2): compares the message with scam campaigns already seen in Tunisia.

Each campaign is a set of key ideas; a message matches when it contains most of them.
The list lives in data/known_scams.json and grows with user reports (step 6).
"""

import json
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path

from .evidence import CheckStatus, Evidence, Signal

DATA_FILE = Path(__file__).resolve().parents[1] / "data" / "known_scams.json"


def normalize(text: str) -> str:
    """Lower case, no accents, no links or masked tags: only words are compared."""
    text = re.sub(r"https?://\S+|www\.\S+|\[[A-Z]+\]", " ", text.lower())
    text = unicodedata.normalize("NFKD", text)
    text = "".join(c for c in text if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", text)


@dataclass(frozen=True)
class KnownScam:
    id: str
    title: str
    # Each idea is a list of synonyms; an idea is present when one synonym is.
    ideas: tuple[tuple[str, ...], ...]
    min_ideas: int

    def score(self, normalized_text: str) -> int:
        return sum(any(normalize(word) in normalized_text for word in idea) for idea in self.ideas)


def load_known_scams(path: Path = DATA_FILE) -> list[KnownScam]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    return [
        KnownScam(
            id=item["id"],
            title=item["title"],
            ideas=tuple(tuple(idea) for idea in item["ideas"]),
            min_ideas=item.get("minIdeas", len(item["ideas"]) - 1),
        )
        for item in raw
    ]


class KnownScamMatcher:
    def __init__(self, scams: list[KnownScam] | None = None) -> None:
        self.scams = scams if scams is not None else load_known_scams()

    def run(self, text: str) -> list[Evidence]:
        normalized = normalize(text)
        best: tuple[int, KnownScam] | None = None
        for scam in self.scams:
            matched = scam.score(normalized)
            if matched >= scam.min_ideas and (best is None or matched > best[0]):
                best = (matched, scam)
        if best is None:
            return []
        matched, scam = best
        return [
            Evidence(
                source="PhishGuard known scams",
                kind="known_scam",
                status=CheckStatus.OK,
                signal=Signal.WARNING,
                text=f"The message looks like a known scam: {scam.title}.",
                detail=f"Campaign '{scam.id}': {matched} of {len(scam.ideas)} key ideas found",
                weight=40,
            )
        ]
