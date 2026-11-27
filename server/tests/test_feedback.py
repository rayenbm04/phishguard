"""Step 6: feedback, scam reports and accuracy measurement."""

import asyncio

from fastapi.testclient import TestClient

from phishguard_server.evaluate import DEFAULT_SET, evaluate
from phishguard_server.main import app, get_pipeline
from phishguard_server.stats import evaluation_metrics

from .fakes import FakeWeb, pipeline

app.dependency_overrides[get_pipeline] = lambda: pipeline(FakeWeb(listed={"amende-tn.info"}))
client = TestClient(app)


def analyse(text: str) -> dict:
    body = {"message": {"text": text, "maskedItems": 0, "language": "fr"}, "appVersion": "test"}
    response = client.post("/analyse", json=body)
    assert response.status_code == 200
    return response.json()


def test_verdicts_are_kept_without_the_message(stores):
    verdict = analyse("Votre amende : https://amende-tn.info/pay")
    saved = stores.verdicts.all()
    assert saved[0]["id"] == verdict["id"] and saved[0]["level"] == "FRAUDULENT"
    assert "amende" not in str(saved)  # Privacy: no text stored.


def test_rating_is_saved(stores):
    verdict = analyse("Bonjour, on se voit demain ?")
    r = client.post("/feedback", json={"verdictId": verdict["id"], "rating": 4})
    assert r.status_code == 201
    assert stores.feedback.all()[0]["rating"] == 4
    assert stores.scam_candidates.all() == []


def test_report_creates_a_candidate_for_review(stores):
    verdict = analyse("Bonjour, on se voit demain ?")
    body = {"verdictId": verdict["id"], "reportedAsScam": True, "maskedText": "Payez [PHONE]"}
    assert client.post("/feedback", json=body).status_code == 201  # A report needs no rating.
    candidate = stores.scam_candidates.all()[0]
    assert candidate["maskedText"] == "Payez [PHONE]" and candidate["status"] == "to_review"
    assert "maskedText" not in stores.feedback.all()[0]  # Text kept only with the candidate.


def test_feedback_rules():
    # Text without a report, or nothing at all: refused.
    assert (
        client.post(
            "/feedback", json={"verdictId": "x", "rating": 3, "maskedText": "a"}
        ).status_code
        == 422
    )
    assert client.post("/feedback", json={"verdictId": "x"}).status_code == 422
    assert client.post("/feedback", json={"verdictId": "x", "rating": 6}).status_code == 422


def test_stats_count_missed_scams(stores):
    safe = analyse("Bonjour, on se voit demain ?")
    scam = analyse("Votre amende : https://amende-tn.info/pay")
    client.post("/feedback", json={"verdictId": safe["id"], "rating": 1, "reportedAsScam": True})
    client.post("/feedback", json={"verdictId": scam["id"], "rating": 5})
    stats = client.get("/stats").json()
    assert stats["verdicts"]["total"] == 2
    assert stats["verdicts"]["byLevel"]["FRAUDULENT"] == 1
    assert stats["feedback"]["averageRating"] == 3.0
    assert stats["feedback"]["helpfulRate"] == 0.5
    assert stats["feedback"]["missedScams"] == 1


def test_evaluation_metrics():
    m = evaluation_metrics(
        [("scam", "FRAUDULENT"), ("scam", "SAFE"), ("legit", "SAFE"), ("legit", "SUSPICIOUS"),
         ("scam", "UNSURE")]
    )  # fmt: skip
    assert m["precision"] == 0.5 and m["recall"] == 0.5
    assert m["coverage"] == 0.8
    assert m["confusion"]["unsure"] == 1


def test_offline_evaluation_runs_on_the_default_set():
    metrics, results = asyncio.run(evaluate(DEFAULT_SET))
    assert metrics["messages"] == len(results) >= 40
    # Guard rail: a change in the rules must not make PhishGuard much worse.
    assert metrics["precision"] >= 0.85 and metrics["recall"] >= 0.8
