"""Measure the accuracy of PhishGuard on a labelled set of messages.

    python -m phishguard_server.evaluate                 # rules only, no network (reproducible)
    python -m phishguard_server.evaluate --online        # with the real services (keys in .env)
    python -m phishguard_server.evaluate my_set.jsonl    # another set

Each line of the set: {"label": "scam" | "legit", "language": "fr" | "ar" | "en", "text": "..."}.
The default set (data/eval_set.jsonl) is synthetic: add real, anonymised messages to it.
"""

import argparse
import asyncio
import json
import logging
from datetime import datetime
from pathlib import Path

import httpx

from .analysis import AnalysisPipeline
from .analysis.clues import Clues
from .analysis.domain_check import DomainCheck
from .config import Settings
from .models import AnalyseRequest
from .stats import evaluation_metrics

DEFAULT_SET = Path(__file__).resolve().parent / "data" / "eval_set.jsonl"


class _NoRdap:
    """Offline: domain age is unknown (NOT_APPLICABLE), never FAILED."""

    async def registration_date(self, domain: str) -> datetime | None:
        return None


class _NoLinkReputation:
    async def run(self, clues: Clues) -> list:
        return []


def offline_pipeline(http: httpx.AsyncClient) -> AnalysisPipeline:
    """The real rules and text checks, without Safe Browsing, VirusTotal, RDAP or the AI."""
    pipeline = AnalysisPipeline(Settings(), http)
    pipeline.links = _NoLinkReputation()
    pipeline.domains = DomainCheck(_NoRdap())
    return pipeline


def load_set(path: Path) -> list[dict]:
    return [
        json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()
    ]


async def evaluate(path: Path, online: bool = False) -> tuple[dict, list[dict]]:
    items = load_set(path)
    results = []
    async with httpx.AsyncClient(timeout=Settings().http_timeout) as http:
        pipeline = AnalysisPipeline(Settings.load(), http) if online else offline_pipeline(http)
        for item in items:
            request = AnalyseRequest.model_validate(
                {
                    "message": {
                        "text": item["text"],
                        "maskedItems": 0,
                        "language": item["language"],
                    },
                    "appVersion": "evaluate",
                }
            )
            verdict = await pipeline.run(request)
            results.append(
                {**item, "predicted": verdict.level.value, "riskScore": verdict.risk_score}
            )
    metrics = evaluation_metrics([(r["label"], r["predicted"]) for r in results])
    return metrics, results


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("dataset", nargs="?", type=Path, default=DEFAULT_SET)
    parser.add_argument("--online", action="store_true", help="use the real external services")
    args = parser.parse_args()
    logging.getLogger("uvicorn.error").setLevel(logging.ERROR)  # No "AI not used" lines.

    metrics, results = asyncio.run(evaluate(args.dataset, args.online))
    wrong = [
        r
        for r in results
        if (r["label"] == "scam" and r["predicted"] == "SAFE")
        or (r["label"] == "legit" and r["predicted"] in {"FRAUDULENT", "SUSPICIOUS"})
    ]
    print(json.dumps(metrics, indent=2))
    if wrong:
        print("\nMistakes:")
        for r in wrong:
            text = r["text"][:90]
            print(f"- expected {r['label']}, got {r['predicted']} ({r['riskScore']}): {text}")


if __name__ == "__main__":
    main()
