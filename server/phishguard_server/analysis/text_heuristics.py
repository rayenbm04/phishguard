"""TextHeuristicCheck (SD2): warning signs in the words themselves, with or without a link."""

from .clues import Clues, ClueType
from .evidence import CheckStatus, Evidence, Signal
from .known_scams import normalize

_SECRET = [
    "code de verification", "code secret", "code sms", "code otp", "otp", "mot de passe",
    "cvv", "cvc", "code pin", " pin ", "identifiant", "password", "passcode",
    "verification code", "security code", "login details", "رمز", "كلمة السر", "كود",
]  # fmt: skip
# A real bank OTP says "never share it"; a scam asks you to send it.
_ASK_VERB = [
    "envoyez", "envoie", "renvoyez", "renvoie", "communiquez-nous", "donnez", "transmettez",
    "saisissez", "confirmez", "send", "share it with us", "give us", "reply with", "enter",
    "ابعث", "أرسل", "عطيني", "ابعثلي",
]  # fmt: skip
_NEVER_SHARE = [
    "ne le communiquez", "ne le partagez", "ne le donnez", "never share", "do not share",
    "don't share", "لا تشارك", "لا تعطي",
]  # fmt: skip
_FEE_TOPIC = [
    "colis", "livraison", "frais", "amende", "douane", "parcel", "delivery", "fee", "fine",
    "customs", "طرد", "رسوم", "مخالفة", "ديوانة",
]  # fmt: skip
_PRIZE = [
    "gagne", "gagnant", "felicitations", "cadeau", "tirage", "won", "winner",
    "congratulations", "prize", "lottery", "ربحت", "مبروك", "جائزة", "هدية",
]  # fmt: skip
_THREAT = ["bloque", "suspendu", "desactive", "ferme", "blocked", "suspended", "locked",
           "closed", "موقوف", "مجمد", "معلق"]  # fmt: skip
_ACCOUNT = ["compte", "carte", "account", "card", "ligne", "حساب", "بطاقة", "خط"]
_CALL = ["appelez", "rappelez", "contactez le", "call", "اتصل", "كلمنا", "عيطلنا"]
_FAMILY = ["nouveau numero", "change de numero", "new number", "رقم جديد", "نومرو جديد"]


def _has(text: str, words: list[str]) -> list[str]:
    padded = f" {text} "
    return [w for w in words if normalize(w) in padded]


class TextHeuristicCheck:
    def run(self, text: str, clues: Clues) -> list[Evidence]:
        t = normalize(text)
        found: list[Evidence] = []

        def add(kind: str, sentence: str, words: list[str], weight: int) -> None:
            detail = "Words: " + ", ".join(f'"{w.strip()}"' for w in words[:3]) if words else None
            found.append(
                Evidence(
                    "PhishGuard", kind, CheckStatus.OK, Signal.WARNING, sentence, detail, weight
                )
            )

        urgent = clues.of(ClueType.URGENT_WORD)
        amounts = clues.of(ClueType.AMOUNT)
        phones = clues.of(ClueType.PHONE)

        secret = _has(t, _SECRET)
        if secret and _has(t, _ASK_VERB) and not _has(t, _NEVER_SHARE):
            add("asks_secret", "The message asks for a secret code or password.", secret, 35)
        if (fee := _has(t, _FEE_TOPIC)) and amounts:
            add("small_fee", "The message asks you to pay a fee to receive something.", fee, 20)
        if prize := _has(t, _PRIZE):
            add("prize", "The message promises a prize or a gift.", prize, 20)
        if (threat := _has(t, _THREAT)) and _has(t, _ACCOUNT):
            add(
                "account_threat", "The message threatens to block your account or card.", threat, 20
            )
        if (call := _has(t, _CALL)) and phones:
            add("call_back", "The message pushes you to call a number it gives.", call, 15)
        if family := _has(t, _FAMILY):
            add("new_number", "Someone says they changed their phone number.", family, 25)
        if urgent and (amounts or clues.links or phones):
            add("pressure", "The message rushes you to pay, click or call.", urgent, 15)
        return found
