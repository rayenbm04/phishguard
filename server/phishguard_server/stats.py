"""Accuracy measurement.

Two views:
- live_stats(): what users think of the verdicts they received (ratings and reports);
- evaluation_metrics(): precision / recall on a labelled test set (see evaluate.py).
"""

from collections import Counter
from typing import Any

LEVELS = ["FRAUDULENT", "SUSPICIOUS", "SAFE", "UNSURE"]
SCAM_LEVELS = {"FRAUDULENT", "SUSPICIOUS"}


def _ratio(part: int, whole: int) -> float | None:
    return round(part / whole, 3) if whole else None


def live_stats(verdicts: list[dict], feedback: list[dict]) -> dict[str, Any]:
    by_level = Counter(v.get("level") for v in verdicts)
    level_of = {v["id"]: v.get("level") for v in verdicts if "id" in v}

    ratings = [f["rating"] for f in feedback if f.get("rating")]
    reports = [f for f in feedback if f.get("reportedAsScam")]
    # A scam reported by the user while PhishGuard said SAFE: a missed scam.
    missed = [f for f in reports if level_of.get(f.get("verdictId")) == "SAFE"]

    return {
        "verdicts": {
            "total": len(verdicts),
            "byLevel": {level: by_level.get(level, 0) for level in LEVELS},
            "unsureRate": _ratio(by_level.get("UNSURE", 0), len(verdicts)),
        },
        "feedback": {
            "total": len(feedback),
            "ratings": len(ratings),
            "averageRating": round(sum(ratings) / len(ratings), 2) if ratings else None,
            # Share of ratings of 4 or 5 stars: users who found the verdict right.
            "helpfulRate": _ratio(sum(r >= 4 for r in ratings), len(ratings)),
            "reportedAsScam": len(reports),
            "missedScams": len(missed),
        },
    }


def evaluation_metrics(rows: list[tuple[str, str]]) -> dict[str, Any]:
    """rows: (expected, predicted level). expected is "scam" or "legit".

    FRAUDULENT and SUSPICIOUS count as "scam", SAFE as "legit".
    UNSURE answers are counted apart (coverage): they are neither right nor wrong.
    """
    decided = [(e, p) for e, p in rows if p != "UNSURE"]
    tp = sum(e == "scam" and p in SCAM_LEVELS for e, p in decided)
    fp = sum(e == "legit" and p in SCAM_LEVELS for e, p in decided)
    fn = sum(e == "scam" and p == "SAFE" for e, p in decided)
    tn = sum(e == "legit" and p == "SAFE" for e, p in decided)
    precision = _ratio(tp, tp + fp)
    recall = _ratio(tp, tp + fn)
    f1 = round(2 * precision * recall / (precision + recall), 3) if precision and recall else None
    return {
        "messages": len(rows),
        "coverage": _ratio(len(decided), len(rows)),  # Share not answered UNSURE.
        "accuracy": _ratio(tp + tn, len(decided)),
        "precision": precision,  # Of the messages flagged, how many were scams.
        "recall": recall,  # Of the scams, how many were flagged.
        "f1": f1,
        "confusion": {
            "truePositive": tp,
            "falsePositive": fp,
            "falseNegative": fn,
            "trueNegative": tn,
            "unsure": len(rows) - len(decided),
        },
    }
