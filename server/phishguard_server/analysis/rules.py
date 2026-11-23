"""SafetyRules (SD2): fixed rules decide the level. The AI never decides, it only explains.

1. A blacklisted link is always FRAUDULENT.
2. A brand look-alike on a new, risky or IP-address site is FRAUDULENT.
3. Hidden instructions for the AI make a message at least SUSPICIOUS.
4. Otherwise the risk score (sum of weights) decides.
5. A FAILED check can never give SAFE: the answer becomes UNSURE.
6. A message without a link is SAFE only when its words show no warning sign at all
   and it asks for no call or payment; otherwise it is UNSURE.
"""

from dataclasses import dataclass

from ..models import VerdictLevel
from .evidence import CheckStatus, Evidence, Signal

FRAUD_SCORE = 70
SUSPICIOUS_SCORE = 35


@dataclass(frozen=True)
class Decision:
    level: VerdictLevel
    risk_score: int


class SafetyRules:
    def decide(
        self, evidence: list[Evidence], has_links: bool, asks_call_or_money: bool = False
    ) -> Decision:
        kinds = {e.kind for e in evidence if e.status == CheckStatus.OK}
        score = min(100, sum(e.weight for e in evidence if e.status == CheckStatus.OK))
        failed = any(e.status == CheckStatus.FAILED for e in evidence)

        if any(e.kind == "blacklisted" and e.signal == Signal.DANGER for e in evidence):
            return Decision(VerdictLevel.FRAUDULENT, max(score, 90))
        if "lookalike" in kinds and kinds & {"new_domain", "risky_tld", "ip_address", "punycode"}:
            return Decision(VerdictLevel.FRAUDULENT, max(score, 85))
        if score >= FRAUD_SCORE:
            return Decision(VerdictLevel.FRAUDULENT, score)
        if score >= SUSPICIOUS_SCORE or "prompt_injection" in kinds:
            return Decision(VerdictLevel.SUSPICIOUS, max(score, SUSPICIOUS_SCORE))
        if failed:
            return Decision(VerdictLevel.UNSURE, max(score, 40))
        if not has_links and (score > 0 or asks_call_or_money):
            return Decision(VerdictLevel.UNSURE, max(score, 40))
        return Decision(VerdictLevel.SAFE, min(score, 20))
