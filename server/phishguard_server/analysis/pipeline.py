"""AnalysisPipeline (SD2): guard -> clues -> checks -> rules -> AI explanation."""

import asyncio
import logging
import time
from datetime import datetime, timezone
from uuid import uuid4

import httpx

from ..config import Settings
from ..models import AnalyseRequest, Verdict
from .cache import ReputationCache
from .clients import RdapClient, SafeBrowsingClient, VirusTotalClient
from .clues import ClueExtractor, Clues, ClueType
from .contacts import OfficialContactDirectory
from .domain_check import DomainCheck
from .evidence import Evidence
from .explainer import LLMExplainer
from .injection_guard import InjectionGuard
from .known_scams import KnownScamMatcher
from .link_reputation import LinkReputationCheck
from .llm import LLMClient
from .rules import SafetyRules
from .text_heuristics import TextHeuristicCheck

# uvicorn prints this logger in the server console.
log = logging.getLogger("uvicorn.error")


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
        self.known_scams = KnownScamMatcher()
        self.text_check = TextHeuristicCheck()
        self.rules = SafetyRules()
        self.contacts = OfficialContactDirectory()
        self.explainer = LLMExplainer(
            LLMClient(http, settings.llm_provider, settings.llm_api_key, settings.llm_model)
        )

    async def run(self, request: AnalyseRequest) -> Verdict:
        started = time.monotonic()
        text = request.message.text
        evidence: list[Evidence] = []

        found = self.guard.scan(text)
        if found:
            text = self.guard.sanitize(text)
            evidence.append(self.guard.evidence(found))

        clues = self.extractor.extract(text, request.source_app)
        evidence += self.known_scams.run(text)
        evidence += self.text_check.run(text, clues)
        evidence += await self._network_checks(clues)

        has_links = bool(clues.links)
        asks = bool(clues.of(ClueType.PHONE) or clues.of(ClueType.AMOUNT))
        decision = self.rules.decide(evidence, has_links, asks)

        time_left = self.settings.total_budget - (time.monotonic() - started)
        summary, reasons, advice = await self.explainer.explain(
            decision,
            evidence,
            has_links,
            self.contacts.contacts_for(evidence),
            text,
            request.reply_language or request.message.language,
            timeout=time_left,
        )
        if self.explainer.last_error:
            log.warning("AI explanation not used: %s", self.explainer.last_error)
        return Verdict(
            id=str(uuid4()),
            level=decision.level,
            risk_score=decision.risk_score,
            summary=summary,
            checked_at=datetime.now(timezone.utc),
            reasons=reasons,
            advice=advice,
        )

    async def _network_checks(self, clues: Clues) -> list[Evidence]:
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
