"""LinkReputationCheck (SD3): Safe Browsing first, VirusTotal only when needed."""

from urllib.parse import urlsplit

from .cache import ReputationCache
from .clients import CheckError, SafeBrowsingClient, VirusTotalClient, normalize_url
from .clues import Clues
from .domains import host_of
from .evidence import CheckStatus, Evidence, Signal

MAX_LINKS = 5


def _cache_key(url: str) -> str:
    parts = urlsplit(normalize_url(url))
    return f"{parts.netloc.lower()}{parts.path or '/'}?{parts.query}"


class LinkReputationCheck:
    def __init__(
        self,
        safe_browsing: SafeBrowsingClient,
        virustotal: VirusTotalClient,
        cache: ReputationCache[list[Evidence]],
    ) -> None:
        self.safe_browsing = safe_browsing
        self.virustotal = virustotal
        self.cache = cache

    async def run(self, clues: Clues) -> list[Evidence]:
        evidence: list[Evidence] = []
        for url in clues.links[:MAX_LINKS]:
            key = _cache_key(url)
            cached = self.cache.get(key)
            if cached is not None:
                evidence += cached
                continue
            found = await self._check(url)
            if all(e.status != CheckStatus.FAILED for e in found):
                self.cache.put(key, found)  # Never cache a failure.
            evidence += found
        return evidence

    async def _check(self, url: str) -> list[Evidence]:
        host = host_of(url)
        try:
            sb = await self.safe_browsing.lookup(url)
        except CheckError as exc:
            sb_evidence = Evidence.failed("Google Safe Browsing", "link_reputation", str(exc))
            # Still ask VirusTotal: it may prove the link is dangerous.
            return [sb_evidence, *await self._virustotal(url, host)]
        if sb.listed:
            kinds = ", ".join(t.lower().replace("_", " ") for t in sb.threat_types)
            return [
                Evidence(
                    source="Google Safe Browsing",
                    kind="blacklisted",
                    status=CheckStatus.OK,
                    signal=Signal.DANGER,
                    text="The link is on Google's list of dangerous sites.",
                    detail=f"{host} is flagged as {kinds}",
                    weight=100,
                )
            ]
        clean = Evidence(
            source="Google Safe Browsing",
            kind="link_reputation",
            status=CheckStatus.OK,
            signal=Signal.CLEAN,
            text="Google Safe Browsing does not list the link.",
            detail=f"{host} is not on the list (new scam sites are often not listed yet)",
        )
        return [clean, *await self._virustotal(url, host)]

    async def _virustotal(self, url: str, host: str) -> list[Evidence]:
        try:
            vt = await self.virustotal.get_report(url)
        except CheckError as exc:
            return [Evidence.failed("VirusTotal", "link_reputation", str(exc))]
        if not vt.known:
            return [
                Evidence(
                    source="VirusTotal",
                    kind="link_reputation",
                    status=CheckStatus.OK,
                    signal=Signal.INFO,
                    text="VirusTotal has never seen this link.",
                    detail=f"No report for {host}",
                )
            ]
        detail = f"{vt.malicious} of {vt.engines} security engines flag {host} as malicious"
        if vt.malicious >= 2:
            return [
                Evidence(
                    source="VirusTotal",
                    kind="blacklisted",
                    status=CheckStatus.OK,
                    signal=Signal.DANGER,
                    text=f"{vt.malicious} security engines flag the link as malicious.",
                    detail=detail,
                    weight=80,
                )
            ]
        if vt.malicious == 1 or vt.suspicious >= 2:
            return [
                Evidence(
                    source="VirusTotal",
                    kind="flagged_once",
                    status=CheckStatus.OK,
                    signal=Signal.WARNING,
                    text="A security engine flags the link as risky.",
                    detail=f"{detail}, {vt.suspicious} as suspicious",
                    weight=25,
                )
            ]
        return [
            Evidence(
                source="VirusTotal",
                kind="link_reputation",
                status=CheckStatus.OK,
                signal=Signal.CLEAN,
                text="No security engine on VirusTotal flags the link.",
                detail=detail,
            )
        ]
