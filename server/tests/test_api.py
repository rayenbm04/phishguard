import json
from pathlib import Path

from fastapi.testclient import TestClient

from phishguard_server.main import app, get_pipeline

from .fakes import FakeWeb, pipeline

web = FakeWeb(listed={"amende-tn.info"})
app.dependency_overrides[get_pipeline] = lambda: pipeline(web)
client = TestClient(app)
CONTRACTS = Path(__file__).resolve().parents[2] / "contracts"


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_analyse_example_request():
    body = json.loads((CONTRACTS / "analyse_request.example.json").read_text(encoding="utf-8"))
    response = client.post("/analyse", json=body)
    assert response.status_code == 200
    verdict = response.json()
    assert verdict["level"] == "FRAUDULENT"
    assert verdict["reasons"][0]["evidenceSource"] == "Google Safe Browsing"
    assert {"riskScore", "checkedAt", "advice"} <= verdict.keys()


def test_analyse_rejects_empty_message():
    body = {"message": {"text": "", "maskedItems": 0, "language": "fr"}, "appVersion": "0.1.0"}
    assert client.post("/analyse", json=body).status_code == 422


def test_feedback_is_accepted():
    body = json.loads((CONTRACTS / "feedback.example.json").read_text(encoding="utf-8"))
    response = client.post("/feedback", json=body)
    assert response.status_code == 201
