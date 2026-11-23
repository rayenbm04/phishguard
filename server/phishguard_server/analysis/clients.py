"""Clients for the external services (SD3). Each one raises CheckError when it cannot answer."""

import base64
from dataclasses import dataclass
from datetime import datetime

import httpx

from .. import __version__


class CheckError(Exception):
    """The service could not give an answer (missing key, timeout, quota, error)."""


def normalize_url(url: str) -> str:
    return url if "://" in url else "http://" + url


@dataclass(frozen=True)
class SafeBrowsingResult:
    listed: bool
    threat_types: tuple[str, ...] = ()


class SafeBrowsingClient:
    URL = "https://safebrowsing.googleapis.com/v4/threatMatches:find"

    def __init__(self, http: httpx.AsyncClient, api_key: str) -> None:
        self.http, self.api_key = http, api_key

    async def lookup(self, url: str) -> SafeBrowsingResult:
        if not self.api_key:
            raise CheckError("GOOGLE_SAFE_BROWSING_API_KEY is not set")
        body = {
            "client": {"clientId": "phishguard", "clientVersion": __version__},
            "threatInfo": {
                "threatTypes": [
                    "MALWARE",
                    "SOCIAL_ENGINEERING",
                    "UNWANTED_SOFTWARE",
                    "POTENTIALLY_HARMFUL_APPLICATION",
                ],
                "platformTypes": ["ANY_PLATFORM"],
                "threatEntryTypes": ["URL"],
                "threatEntries": [{"url": normalize_url(url)}],
            },
        }
        try:
            response = await self.http.post(self.URL, params={"key": self.api_key}, json=body)
        except httpx.HTTPError as exc:
            raise CheckError(f"Safe Browsing unreachable: {type(exc).__name__}") from exc
        if response.status_code != 200:
            raise CheckError(f"Safe Browsing answered HTTP {response.status_code}")
        matches = response.json().get("matches", [])
        return SafeBrowsingResult(
            listed=bool(matches),
            threat_types=tuple(sorted({m.get("threatType", "UNKNOWN") for m in matches})),
        )


@dataclass(frozen=True)
class VirusTotalResult:
    known: bool  # False when VirusTotal has never scanned this URL.
    malicious: int = 0
    suspicious: int = 0
    engines: int = 0


class VirusTotalClient:
    URL = "https://www.virustotal.com/api/v3/urls/{id}"

    def __init__(self, http: httpx.AsyncClient, api_key: str) -> None:
        self.http, self.api_key = http, api_key

    async def get_report(self, url: str) -> VirusTotalResult:
        if not self.api_key:
            raise CheckError("VIRUSTOTAL_API_KEY is not set")
        url_id = base64.urlsafe_b64encode(normalize_url(url).encode()).decode().rstrip("=")
        try:
            response = await self.http.get(
                self.URL.format(id=url_id), headers={"x-apikey": self.api_key}
            )
        except httpx.HTTPError as exc:
            raise CheckError(f"VirusTotal unreachable: {type(exc).__name__}") from exc
        if response.status_code == 404:
            return VirusTotalResult(known=False)
        if response.status_code == 429:
            raise CheckError("VirusTotal quota reached (4 requests per minute)")
        if response.status_code != 200:
            raise CheckError(f"VirusTotal answered HTTP {response.status_code}")
        stats = response.json()["data"]["attributes"].get("last_analysis_stats", {})
        return VirusTotalResult(
            known=True,
            malicious=int(stats.get("malicious", 0)),
            suspicious=int(stats.get("suspicious", 0)),
            engines=sum(int(v) for v in stats.values()),
        )


class RdapClient:
    """Domain registration date through rdap.org (redirects to the right registry)."""

    URL = "https://rdap.org/domain/{domain}"

    def __init__(self, http: httpx.AsyncClient) -> None:
        self.http = http

    async def registration_date(self, domain: str) -> datetime | None:
        """None when the registry has no RDAP service or no date for this domain."""
        try:
            response = await self.http.get(
                self.URL.format(domain=domain),
                headers={"Accept": "application/rdap+json"},
                follow_redirects=True,
            )
        except httpx.HTTPError as exc:
            raise CheckError(f"RDAP unreachable: {type(exc).__name__}") from exc
        if response.status_code == 404:
            return None
        if response.status_code != 200:
            raise CheckError(f"RDAP answered HTTP {response.status_code}")
        for event in response.json().get("events", []):
            if event.get("eventAction") == "registration" and event.get("eventDate"):
                try:
                    return datetime.fromisoformat(event["eventDate"].replace("Z", "+00:00"))
                except ValueError:
                    return None
        return None
