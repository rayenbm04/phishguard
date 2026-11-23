import json
from pathlib import Path

from fastapi.testclient import TestClient

from phishguard_server.main import app

client = TestClient(app)
CONTRACTS = Path(__file__).resolve().parents[2] / "contracts"


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_analyse_returns_unsure_placeholder():
    body = json.loads((CONTRACTS / "analyse_request.example.json").read_text(encoding="utf-8"))
    response = client.post("/analyse", json=body)
    assert response.status_code == 200
    verdict = response.json()
    assert verdict["level"] == "UNSURE"
    assert "riskScore" in verdict and verdict["reasons"]


def test_analyse_rejects_empty_message():
    body = {"message": {"text": "", "maskedItems": 0, "language": "fr"}, "appVersion": "0.1.0"}
    assert client.post("/analyse", json=body).status_code == 422


def test_feedback_is_accepted():
    body = json.loads((CONTRACTS / "feedback.example.json").read_text(encoding="utf-8"))
    response = client.post("/feedback", json=body)
    assert response.status_code == 201
