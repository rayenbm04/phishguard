"""Evidence: what each check found. SafetyRules decide from evidence only."""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum


class CheckStatus(str, Enum):
    OK = "OK"  # The check ran and gave an answer.
    FAILED = "FAILED"  # The check could not answer (timeout, error, missing key).
    NOT_APPLICABLE = "NOT_APPLICABLE"  # Nothing to check (e.g. a .tn domain without RDAP).


class Signal(str, Enum):
    DANGER = "DANGER"  # Proof of a scam (blacklisted link...).
    WARNING = "WARNING"  # A warning sign (new domain, look-alike brand...).
    INFO = "INFO"  # Neutral fact, shown for context.
    CLEAN = "CLEAN"  # The check found nothing wrong.


@dataclass
class Evidence:
    source: str  # Who says it: "Google Safe Browsing", "VirusTotal", "RDAP", "PhishGuard"
    kind: str  # Short code used by the rules: "blacklisted", "new_domain", "lookalike"...
    status: CheckStatus
    signal: Signal
    text: str  # One sentence for the user.
    detail: str | None = None  # Technical detail shown when the user taps the reason.
    weight: int = 0  # Points added to the risk score.
    brand: str | None = None  # The brand a look-alike imitates.
    checked_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    @classmethod
    def failed(cls, source: str, kind: str, detail: str) -> "Evidence":
        return cls(
            source=source,
            kind=kind,
            status=CheckStatus.FAILED,
            signal=Signal.INFO,
            text=f"{source} could not be checked.",
            detail=detail,
        )
