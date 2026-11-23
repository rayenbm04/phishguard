"""Fake external services: no test ever calls Google, VirusTotal or RDAP for real."""

import base64
import json
from dataclasses import dataclass, field

import httpx

from phishguard_server.analysis import AnalysisPipeline
from phishguard_server.config import Settings


@dataclass
class FakeWeb:
    listed: set[str] = field(default_factory=set)  # Hosts Safe Browsing flags.
    vt_malicious: dict[str, int] = field(default_factory=dict)  # Host -> engines flagging it.
    created: dict[str, str] = field(default_factory=dict)  # Domain -> ISO registration date.
    fail: set[str] = field(default_factory=set)  # "safebrowsing", "virustotal", "rdap".
    calls: list[str] = field(default_factory=list)

    def handler(self, request: httpx.Request) -> httpx.Response:
        host = request.url.host
        if "safebrowsing" in host:
            self.calls.append("safebrowsing")
            if "safebrowsing" in self.fail:
                raise httpx.ConnectTimeout("timeout")
            url = json.loads(request.content)["threatInfo"]["threatEntries"][0]["url"]
            hit = any(h in url for h in self.listed)
            body = {"matches": [{"threatType": "SOCIAL_ENGINEERING"}]} if hit else {}
            return httpx.Response(200, json=body)
        if "virustotal" in host:
            self.calls.append("virustotal")
            if "virustotal" in self.fail:
                return httpx.Response(429, json={})
            url_id = request.url.path.rsplit("/", 1)[-1]
            url = base64.urlsafe_b64decode(url_id + "=" * (-len(url_id) % 4)).decode()
            for flagged, count in self.vt_malicious.items():
                if flagged in url:
                    stats = {"malicious": count, "suspicious": 0, "harmless": 60, "undetected": 20}
                    return httpx.Response(
                        200, json={"data": {"attributes": {"last_analysis_stats": stats}}}
                    )
            return httpx.Response(404, json={})
        if "rdap" in host:
            self.calls.append("rdap")
            if "rdap" in self.fail:
                return httpx.Response(503)
            domain = request.url.path.rsplit("/", 1)[-1]
            if domain not in self.created:
                return httpx.Response(404)
            events = [{"eventAction": "registration", "eventDate": self.created[domain]}]
            return httpx.Response(200, json={"events": events})
        return httpx.Response(500)


def pipeline(web: FakeWeb, keys: bool = True) -> AnalysisPipeline:
    settings = Settings(
        safe_browsing_key="test" if keys else "",
        virustotal_key="test" if keys else "",
    )
    http = httpx.AsyncClient(transport=httpx.MockTransport(web.handler))
    return AnalysisPipeline(settings, http)
