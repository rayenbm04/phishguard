"""ClueExtractor (SD2): finds the parts of a message worth checking."""

import re
from dataclasses import dataclass, field
from enum import Enum


class ClueType(str, Enum):
    LINK = "LINK"
    PHONE = "PHONE"
    AMOUNT = "AMOUNT"
    SENDER = "SENDER"
    URGENT_WORD = "URGENT_WORD"


@dataclass(frozen=True)
class Clue:
    type: ClueType
    value: str


@dataclass
class Clues:
    items: list[Clue] = field(default_factory=list)

    def of(self, kind: ClueType) -> list[str]:
        return [c.value for c in self.items if c.type == kind]

    @property
    def links(self) -> list[str]:
        return self.of(ClueType.LINK)


_TLDS = (
    r"tn|com|net|org|info|xyz|top|online|site|click|live|shop|icu|buzz|ly|me|io|co|"
    r"app|link|vip|support|fr|ma|dz|eg|gov|biz|cfd|sbs|rest|lol|work|monster"
)
_LINK = re.compile(
    r"(?:https?://|www\.)[^\s<>\"'«»]+"
    rf"|\b(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:{_TLDS})\b(?:/[^\s<>\"'«»]*)?",
    re.IGNORECASE,
)
_EMAIL = re.compile(r"\b[\w.+-]+@([\w-]+\.)+[a-z]{2,}\b", re.IGNORECASE)
_AMOUNT = re.compile(
    r"\b\d{1,7}(?:[.,]\d{1,3})?\s?(?:DT|TND|dinars?|millimes?|€|EUR|euros?|\$|USD)(?!\w)"
    r"|(?:€|\$)\s?\d{1,7}(?:[.,]\d{1,2})?"
    r"|\d{1,7}(?:[.,]\d{1,3})?\s?(?:د\.ت|دينار)",
    re.IGNORECASE,
)
# Phones were masked on the phone ([PHONE]); short service numbers stay visible.
_PHONE = re.compile(r"\[PHONE\]|(?<!\d)(?:8\d{7}|\d{4,5})(?=\s|$|[.,;:!?])")
_URGENT = [
    # French
    "urgent", "immédiatement", "immediatement", "sous 24", "sous 48", "dernier rappel",
    "bloqué", "bloque", "suspendu", "expire", "dernier délai", "aujourd'hui", "vite",
    "action requise", "payez", "régularisez", "regularisez", "gagné", "gagnant",
    # English
    "immediately", "within 24", "blocked", "suspended", "final notice", "act now",
    "verify your", "you have won", "winner", "last chance", "expires",
    # Arabic
    "عاجل", "فورا", "فوراً", "حسابك", "موقوف", "تعليق", "ربحت", "آخر أجل",
]  # fmt: skip


class ClueExtractor:
    def extract(self, text: str, source_app: str | None = None) -> Clues:
        items: list[Clue] = []
        without_emails = _EMAIL.sub(" ", text)
        seen: set[str] = set()
        for match in _LINK.finditer(without_emails):
            link = match.group(0).rstrip(".,;:!?)]}")
            if link.lower() not in seen:
                seen.add(link.lower())
                items.append(Clue(ClueType.LINK, link))
        for match in _EMAIL.finditer(text):
            items.append(Clue(ClueType.SENDER, match.group(0)))
        if source_app:
            items.append(Clue(ClueType.SENDER, source_app))
        for match in _AMOUNT.finditer(text):
            items.append(Clue(ClueType.AMOUNT, match.group(0).strip()))
        for match in _PHONE.finditer(text):
            items.append(Clue(ClueType.PHONE, match.group(0)))
        lowered = text.lower()
        for word in _URGENT:
            if word in lowered:
                items.append(Clue(ClueType.URGENT_WORD, word))
        return Clues(items)
