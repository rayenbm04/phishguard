"""OfficialContactDirectory (SD2): verified official contacts. The AI may only pick from it."""

from dataclasses import dataclass

from .domains import TUNISIAN_BRANDS
from .evidence import Evidence


@dataclass(frozen=True)
class OfficialContact:
    id: str
    name: str
    url: str
    purpose: str  # What the contact is for, shown to the AI.


ANCS = OfficialContact(
    id="ancs",
    name="ANCS (Agence nationale de la cybersécurité)",
    url="https://www.ancs.tn",
    purpose="report a scam or a cyber attack in Tunisia",
)


def _contact_id(name: str) -> str:
    return "".join(c if c.isalnum() else "-" for c in name.lower()).strip("-")


class OfficialContactDirectory:
    def __init__(self) -> None:
        self._brands = {
            b.name: OfficialContact(
                id=_contact_id(b.name),
                name=b.name,
                url=f"https://www.{b.official[0]}",
                purpose=f"the official website of {b.name}",
            )
            for b in TUNISIAN_BRANDS
        }

    def contacts_for(self, evidence: list[Evidence]) -> list[OfficialContact]:
        """Contacts of the brands the message imitates, plus the ANCS to report scams."""
        found: list[OfficialContact] = []
        for e in evidence:
            contact = self._brands.get(e.brand or "")
            if contact and contact not in found:
                found.append(contact)
        return [*found, ANCS]
