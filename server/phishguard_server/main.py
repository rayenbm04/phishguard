"""FastAPI entry point: /analyse (SD1-SD3), /feedback (SD6) and /stats (accuracy)."""

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Any

import httpx
from fastapi import Depends, FastAPI, Request

from . import __version__
from .analysis import AnalysisPipeline
from .config import Settings
from .models import AnalyseRequest, Feedback, Verdict
from .stats import live_stats
from .storage import Stores


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = Settings.load()
    app.state.stores = Stores(settings.data_dir)
    async with httpx.AsyncClient(timeout=settings.http_timeout) as http:
        app.state.pipeline = AnalysisPipeline(settings, http)
        llm = app.state.pipeline.explainer.llm
        logging.getLogger("uvicorn.error").info(
            "PhishGuard %s | Safe Browsing key: %s | VirusTotal key: %s | AI: %s (%s), key: %s",
            __version__,
            "set" if settings.safe_browsing_key else "MISSING",
            "set" if settings.virustotal_key else "MISSING",
            llm.provider,
            llm.model,
            "set" if llm.enabled else "MISSING",
        )
        yield


app = FastAPI(title="PhishGuard API", version=__version__, lifespan=lifespan)


def get_pipeline(request: Request) -> AnalysisPipeline:
    return request.app.state.pipeline


def get_stores(request: Request) -> Stores:
    return request.app.state.stores


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "version": __version__}


@app.post("/analyse", response_model=Verdict, response_model_by_alias=True)
async def analyse(
    request: AnalyseRequest,
    pipeline: AnalysisPipeline = Depends(get_pipeline),
    stores: Stores = Depends(get_stores),
) -> Verdict:
    verdict = await pipeline.run(request)
    # Kept for the statistics: the verdict only, never the message.
    stores.verdicts.append(
        {
            "id": verdict.id,
            "level": verdict.level.value,
            "riskScore": verdict.risk_score,
            "checkedAt": verdict.checked_at.isoformat(),
            "language": request.message.language.value,
        }
    )
    return verdict


@app.post("/feedback", status_code=201)
def feedback(item: Feedback, stores: Stores = Depends(get_stores)) -> dict[str, str]:
    now = datetime.now(timezone.utc).isoformat()
    stores.feedback.append(
        {
            "verdictId": item.verdict_id,
            "rating": item.rating,
            "reportedAsScam": item.reported_as_scam,
            "comment": item.comment,
            "receivedAt": now,
        }
    )
    if item.reported_as_scam and item.masked_text:
        # Reviewed by the team before it enters data/known_scams.json (SD6).
        stores.scam_candidates.append(
            {
                "verdictId": item.verdict_id,
                "maskedText": item.masked_text,
                "receivedAt": now,
                "status": "to_review",
            }
        )
    return {"status": "received", "verdictId": item.verdict_id}


@app.get("/stats")
def stats(stores: Stores = Depends(get_stores)) -> dict[str, Any]:
    return live_stats(stores.verdicts.all(), stores.feedback.all())
