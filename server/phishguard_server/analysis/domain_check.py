"""DomainCheck (SD3): domain age (RDAP) and comparison with Tunisian brands."""

from datetime import datetime, timezone

from .clients import CheckError, RdapClient
from .clues import Clues
from .domains import (
    RISKY_TLDS,
    URL_SHORTENERS,
    host_of,
    is_ip,
    lookalike_brand,
    registered_domain,
    tld,
)
from .evidence import CheckStatus, Evidence, Signal

MAX_DOMAINS = 3
NO_RDAP_TLDS = {"tn"}  # The .tn registry has no public RDAP service.


class DomainCheck:
    def __init__(self, rdap: RdapClient) -> None:
        self.rdap = rdap

    async def run(self, clues: Clues) -> list[Evidence]:
        evidence: list[Evidence] = []
        seen: list[str] = []
        for url in clues.links:
            host = host_of(url)
            domain = registered_domain(host)
            if not host or domain in seen:
                continue
            seen.append(domain)
            if len(seen) > MAX_DOMAINS:
                break
            evidence += self._static(host, domain)
            if not is_ip(host):
                evidence.append(await self._age(domain))
        return evidence

    def _static(self, host: str, domain: str) -> list[Evidence]:
        found: list[Evidence] = []

        def add(kind: str, text: str, detail: str, weight: int, brand: str | None = None) -> None:
            found.append(
                Evidence(
                    "PhishGuard",
                    kind,
                    CheckStatus.OK,
                    Signal.WARNING,
                    text,
                    detail,
                    weight,
                    brand=brand,
                )
            )

        brand = lookalike_brand(host)
        if brand:
            add(
                "lookalike",
                f"The link imitates {brand.name} but is not its official site.",
                f"{host} is not {', '.join(brand.official)}",
                45,
                brand.name,
            )
        if is_ip(host):
            add("ip_address", "The link uses a bare IP address instead of a name.", host, 30)
        if host.startswith("xn--") or ".xn--" in host:
            add("punycode", "The link uses look-alike letters from another alphabet.", host, 25)
        if domain in URL_SHORTENERS:
            add("shortener", "The link is shortened, which hides the real address.", host, 15)
        if tld(host) in RISKY_TLDS:
            add(
                "risky_tld",
                f'The site ends in ".{tld(host)}", an ending often used by scam sites.',
                host,
                15,
            )
        return found

    async def _age(self, domain: str) -> Evidence:
        if tld(domain) in NO_RDAP_TLDS:
            return Evidence(
                "RDAP",
                "domain_age",
                CheckStatus.NOT_APPLICABLE,
                Signal.INFO,
                "The age of .tn domains cannot be checked automatically.",
                domain,
            )
        try:
            created = await self.rdap.registration_date(domain)
        except CheckError as exc:
            return Evidence.failed("RDAP", "domain_age", str(exc))
        if created is None:
            return Evidence(
                "RDAP",
                "domain_age",
                CheckStatus.NOT_APPLICABLE,
                Signal.INFO,
                "The registration date of the domain is not published.",
                domain,
            )
        days = max(0, (datetime.now(timezone.utc) - created).days)
        detail = f"{domain} was registered on {created.date().isoformat()}"
        if days < 30:
            text = (
                "The site was created today."
                if days == 0
                else f"The site was created {days} day{'s' if days > 1 else ''} ago."
            )
            return Evidence("RDAP", "new_domain", CheckStatus.OK, Signal.WARNING, text, detail, 35)
        if days < 180:
            return Evidence(
                "RDAP",
                "young_domain",
                CheckStatus.OK,
                Signal.WARNING,
                f"The site is only {days // 30} months old.",
                detail,
                15,
            )
        return Evidence(
            "RDAP",
            "domain_age",
            CheckStatus.OK,
            Signal.CLEAN,
            f"The site has existed since {created.year}.",
            detail,
        )
