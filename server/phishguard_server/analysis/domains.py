"""Domain helpers: registered domain, Tunisian brands, look-alike detection."""

import ipaddress
import re
from dataclasses import dataclass

# Second-level suffixes used in Tunisia and elsewhere (enough for our messages).
_TWO_LEVEL_SUFFIXES = {
    "com.tn", "gov.tn", "nat.tn", "org.tn", "ens.tn", "edunet.tn", "rnu.tn",
    "net.tn", "info.tn", "co.uk", "com.fr", "co.ma", "com.eg",
}  # fmt: skip

URL_SHORTENERS = {
    "bit.ly", "tinyurl.com", "t.co", "goo.gl", "is.gd", "cutt.ly", "rb.gy",
    "shorturl.at", "ow.ly", "tiny.cc", "s.id", "rebrand.ly", "t.ly",
}  # fmt: skip

# TLDs that are cheap and very common in phishing campaigns.
RISKY_TLDS = {
    "top", "xyz", "info", "online", "site", "click", "live", "shop", "icu",
    "buzz", "rest", "cfd", "sbs", "lol", "monster", "vip", "work", "support",
}  # fmt: skip


@dataclass(frozen=True)
class Brand:
    name: str
    official: tuple[str, ...]  # Official registered domains.
    keywords: tuple[str, ...]  # Words a fake domain would copy.


TUNISIAN_BRANDS = [
    Brand("La Poste Tunisienne", ("poste.tn",), ("poste", "laposte", "rapid-poste")),
    Brand("Ooredoo", ("ooredoo.tn",), ("ooredoo",)),
    Brand("Orange Tunisie", ("orange.tn", "orange.com", "orange.fr"), ("orange",)),
    Brand("Tunisie Telecom", ("tunisietelecom.tn",), ("tunisietelecom", "tunisie-telecom")),
    Brand("BIAT", ("biat.com.tn",), ("biat",)),
    Brand("STB", ("stb.com.tn",), ("stb",)),
    Brand("BH Bank", ("bh.com.tn",), ("bhbank", "bh-bank")),
    Brand("Attijari Bank", ("attijaribank.com.tn",), ("attijari",)),
    Brand("Amen Bank", ("amenbank.com.tn",), ("amenbank", "amen-bank")),
    Brand("UBCI", ("ubci.tn",), ("ubci",)),
    Brand("Banque Zitouna", ("banquezitouna.com",), ("zitouna",)),
    Brand("CNAM", ("cnam.nat.tn",), ("cnam",)),
    Brand("Ministère des Finances", ("finances.gov.tn",), ("finances", "impots", "amende")),
    Brand("ANCS", ("ancs.tn",), ("ancs",)),
    Brand("Aramex", ("aramex.com", "aramex.tn"), ("aramex",)),
    Brand("DHL", ("dhl.com", "dhl.de"), ("dhl",)),
]


def host_of(url: str) -> str:
    """Host name of a URL, lower case, without port or credentials."""
    rest = re.sub(r"^[a-z][a-z0-9+.-]*://", "", url.strip(), flags=re.IGNORECASE)
    host = re.split(r"[/?#]", rest, maxsplit=1)[0]
    host = host.rsplit("@", 1)[-1]
    if host.startswith("["):  # IPv6
        return host.split("]")[0].strip("[").lower()
    return host.split(":")[0].lower().rstrip(".")


def is_ip(host: str) -> bool:
    try:
        ipaddress.ip_address(host)
        return True
    except ValueError:
        return False


def registered_domain(host: str) -> str:
    """'secure.poste.tn' -> 'poste.tn', 'a.b.biat.com.tn' -> 'biat.com.tn'."""
    if is_ip(host):
        return host
    labels = host.split(".")
    if len(labels) >= 3 and ".".join(labels[-2:]) in _TWO_LEVEL_SUFFIXES:
        return ".".join(labels[-3:])
    return ".".join(labels[-2:])


def tld(host: str) -> str:
    return host.rsplit(".", 1)[-1]


def _distance(a: str, b: str) -> int:
    """Levenshtein distance (small strings only)."""
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def lookalike_brand(host: str) -> Brand | None:
    """The brand a domain imitates, or None. Official domains are never look-alikes."""
    domain = registered_domain(host)
    for brand in TUNISIAN_BRANDS:
        if domain in brand.official:
            return None
    labels = re.split(r"[.-]", host)
    name = domain.split(".")[0]
    for brand in TUNISIAN_BRANDS:
        for keyword in brand.keywords:
            # Short keywords (stb, dhl) must be a whole label, longer ones may be inside one.
            if keyword in labels or (len(keyword) >= 5 and keyword in host):
                return brand
        for official in brand.official:
            official_name = official.split(".")[0]
            if len(official_name) >= 5 and 0 < _distance(name, official_name) <= 2:
                return brand  # e.g. "ooredo", "b1at"... (typosquatting)
    return None
