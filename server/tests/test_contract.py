"""The shared JSON examples in contracts/ must parse and round-trip unchanged."""

import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from phishguard_server.models import AnalyseRequest, Feedback, Verdict

CONTRACTS = Path(__file__).resolve().parents[2] / "contracts"


def load(name: str) -> dict:
    return json.loads((CONTRACTS / name).read_text(encoding="utf-8"))


@pytest.mark.parametrize(
    ("model", "file"),
    [
        (AnalyseRequest, "analyse_request.example.json"),
        (Verdict, "verdict.example.json"),
        (Feedback, "feedback.example.json"),
    ],
)
def test_example_round_trips(model, file):
    data = load(file)
    parsed = model.model_validate(data)
    again = model.model_validate(parsed.model_dump(mode="json", by_alias=True))
    assert again == parsed
    assert set(parsed.model_dump(by_alias=True)) == set(data)


def test_masked_text_requires_a_scam_report():
    data = load("feedback.example.json") | {"reportedAsScam": False}
    with pytest.raises(ValidationError):
        Feedback.model_validate(data)


def test_verdict_needs_a_reason():
    data = load("verdict.example.json") | {"reasons": []}
    with pytest.raises(ValidationError):
        Verdict.model_validate(data)
