"""Shared models (DTOs), see docs/uml: class diagram 3.

JSON uses camelCase keys so the Flutter app and the server read the same payloads.
"""

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field, model_validator
from pydantic.alias_generators import to_camel


class ApiModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class Language(str, Enum):
    FRENCH = "fr"
    ARABIC = "ar"
    ENGLISH = "en"


class VerdictLevel(str, Enum):
    FRAUDULENT = "FRAUDULENT"
    SUSPICIOUS = "SUSPICIOUS"
    SAFE = "SAFE"
    UNSURE = "UNSURE"


class MaskedMessage(ApiModel):
    text: str = Field(min_length=1, max_length=5000)
    masked_items: int = Field(ge=0)
    language: Language


class AnalyseRequest(ApiModel):
    message: MaskedMessage
    source_app: str | None = None
    app_version: str
    # Language of the app: the explanation is written in it. Defaults to the message language.
    reply_language: Language | None = None


class Reason(ApiModel):
    rank: int = Field(ge=1)
    text: str
    evidence_source: str
    evidence_detail: str | None = None
    checked_date: datetime | None = None


class Advice(ApiModel):
    action: str
    official_contact: str | None = None


class Explanation(ApiModel):
    reasons: list[Reason]
    advice: list[Advice]


class Verdict(ApiModel):
    id: str
    level: VerdictLevel
    risk_score: int = Field(ge=0, le=100)
    summary: str
    checked_at: datetime
    reasons: list[Reason] = Field(min_length=1)
    advice: list[Advice] = Field(min_length=1)


class Feedback(ApiModel):
    verdict_id: str
    rating: int = Field(ge=1, le=5)
    reported_as_scam: bool = False
    masked_text: str | None = None
    comment: str | None = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def masked_text_only_when_reported(self) -> "Feedback":
        # Privacy rule: the message text is only sent when the user reports a scam.
        if self.masked_text is not None and not self.reported_as_scam:
            raise ValueError("maskedText is only allowed when reportedAsScam is true")
        return self
