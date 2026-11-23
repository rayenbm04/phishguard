"""AnalysisPipeline (SD2): guard -> clues -> checks in parallel -> rules -> explanation."""

import asyncio
from datetime import datetime, timezone
from uuid import uuid4

import httpx

from ..config import Settings
from ..models import AnalyseRequest, Verdict
from .cache import ReputationCache
from .clients import RdapClient, SafeBrowsingClient, VirusTotalClient
from .clues import ClueExtractor, Clues, ClueType
from .domain_check import DomainCheck
from .evidence import CheckStatus, Evidence, Signal
from .explainer import TemplateExplainer
from .injection_guard import InjectionGuard
from .link_reputation import LinkReputationCheck
from .rules import SafetyRules


def _pressure(clues: Clues) -> list[Evidence]:
    """Urgency plus money or a link: the usual shape of a scam (text checks grow in step 4)."""
    urgent = clues.of(ClueType.URGENT_WORD)
    asks = clues.of(ClueType.AMOUNT) or clues.links
    if not (urgent and asks):
        return []
    return [
        Evidence(
            source="PhishGuard",
            kind="pressure",
            status=CheckStatus.OK,
            signal=Signal.WARNING,
            text="The message rushes you to pay or click.",
            detail="Urgent words: " + ", ".join(f'"{w}"' for w in urgent[:3]),
            weight=15,
        )
    ]


class AnalysisPipeline:
    def __init__(self, settings: Settings, http: httpx.AsyncClient) -> None:
        self.settings = settings
        self.guard = InjectionGuard()
        self.extractor = ClueExtractor()
        self.links = LinkReputationCheck(
            SafeBrowsingClient(http, settings.safe_browsing_key),
            VirusTotalClient(http, settings.virustotal_key),
            ReputationCache(),
        )
        self.domains = DomainCheck(RdapClient(http))
        self.rules = SafetyRules()
        self.explainer = TemplateExplainer()

    async def run(self, request: AnalyseRequest) -> Verdict:
        text = request.message.text
        evidence: list[Evidence] = []

        found = self.guard.scan(text)
        if found:
            text = self.guard.sanitize(text)
            evidence.append(self.guard.evidence(found))

        clues = self.extractor.extract(text, request.source_app)
        evidence += _pressure(clues)
        evidence += await self._run_checks(clues)

        decision = self.rules.decide(evidence, has_links=bool(clues.links))
        summary, reasons, advice = self.explainer.explain(decision, evidence, bool(clues.links))
        return Verdict(
            id=str(uuid4()),
            level=decision.level,
            risk_score=decision.risk_score,
            summary=summary,
            checked_at=datetime.now(timezone.utc),
            reasons=reasons,
            advice=advice,
        )

    async def _run_checks(self, clues: Clues) -> list[Evidence]:
        if not clues.links:
            return []
        checks = {
            "Link reputation": self.links.run(clues),
            "Domain check": self.domains.run(clues),
        }
        tasks = [asyncio.create_task(c) for c in checks.values()]
        _done, pending = await asyncio.wait(tasks, timeout=self.settings.checks_timeout)
        evidence: list[Evidence] = []
        for name, task in zip(checks, tasks, strict=True):
            if task in pending:
                task.cancel()
                evidence.append(Evidence.failed(name, "timeout", "No answer in time"))
            elif task.exception() is not None:
                evidence.append(Evidence.failed(name, "error", repr(task.exception())))
            else:
                evidence += task.result()
        return evidence
