"""TemplateExplainer: turns the decision and the evidence into reasons and advice.

Step 4 replaces the wording with the LLMExplainer (in the user's language);
the level, the score and the evidence stay exactly the same.
"""

from ..models import Advice, Reason, VerdictLevel
from .domains import TUNISIAN_BRANDS, Brand
from .evidence import CheckStatus, Evidence, Signal
from .rules import Decision

MAX_REASONS = 3
ANCS = "https://www.ancs.tn"

_SUMMARY = {
    VerdictLevel.FRAUDULENT: "This message is a scam. Do not act on it.",
    VerdictLevel.SUSPICIOUS: "This message shows warning signs. Be careful.",
    VerdictLevel.SAFE: "No warning sign was found in the checks.",
    VerdictLevel.UNSURE: "PhishGuard could not check everything, so it can't say this is safe.",
}


def _brand_in(evidence: list[Evidence]) -> Brand | None:
    for e in evidence:
        if e.kind == "lookalike":
            for brand in TUNISIAN_BRANDS:
                if brand.name in e.text:
                    return brand
    return None


class TemplateExplainer:
    def explain(
        self, decision: Decision, evidence: list[Evidence], has_links: bool
    ) -> tuple[str, list[Reason], list[Advice]]:
        level = decision.level
        brand = _brand_in(evidence)
        summary = _SUMMARY[level]
        if brand and level in (VerdictLevel.FRAUDULENT, VerdictLevel.SUSPICIOUS):
            summary = f"This message pretends to come from {brand.name}. " + summary

        return summary, self._reasons(level, evidence, has_links), self._advice(level, brand)

    def _reasons(
        self, level: VerdictLevel, evidence: list[Evidence], has_links: bool
    ) -> list[Reason]:
        warnings = sorted(
            (e for e in evidence if e.signal in (Signal.DANGER, Signal.WARNING)),
            key=lambda e: -e.weight,
        )
        failed = [e for e in evidence if e.status == CheckStatus.FAILED]
        clean = [e for e in evidence if e.signal == Signal.CLEAN]

        chosen = warnings[:MAX_REASONS]
        if level == VerdictLevel.UNSURE:
            chosen += failed[: MAX_REASONS - len(chosen)]
        if len(chosen) < MAX_REASONS and level != VerdictLevel.FRAUDULENT:
            chosen += clean[: MAX_REASONS - len(chosen)]

        reasons = [
            Reason(
                rank=i,
                text=e.text,
                evidence_source=e.source,
                evidence_detail=e.detail,
                checked_date=e.checked_at,
            )
            for i, e in enumerate(chosen, 1)
        ]
        if not reasons:
            text = (
                "The message has no link to check. Text analysis arrives in a later version."
                if not has_links
                else "The checks gave no clear answer."
            )
            reasons.append(Reason(rank=1, text=text, evidence_source="PhishGuard"))
        return reasons

    def _advice(self, level: VerdictLevel, brand: Brand | None) -> list[Advice]:
        official = f"https://www.{brand.official[0]}" if brand else None
        if level == VerdictLevel.FRAUDULENT:
            advice = [
                Advice(action="Do not open the link, pay, or call back."),
                Advice(action="Delete the message and block the sender."),
            ]
            if brand:
                advice.append(
                    Advice(
                        action=f"If in doubt, contact {brand.name} through its official site.",
                        official_contact=official,
                    )
                )
            advice.append(Advice(action="Report the scam to the ANCS.", official_contact=ANCS))
            return advice
        if level == VerdictLevel.SUSPICIOUS:
            advice = [
                Advice(action="Do not open the link or share any code until you are sure."),
                Advice(action="Check with the sender through a channel you already know."),
            ]
            if brand:
                advice.append(
                    Advice(
                        action=f"Go to {brand.name}'s official site yourself.",
                        official_contact=official,
                    )
                )
            return advice
        if level == VerdictLevel.SAFE:
            return [
                Advice(action="You can continue, but never share a password or a code you receive.")
            ]
        return [
            Advice(action="Do not open the link yet."),
            Advice(action="Try the check again in a few minutes."),
        ]
