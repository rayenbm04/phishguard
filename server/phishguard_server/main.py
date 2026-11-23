"""FastAPI entry point. Step 3: /analyse runs the real pipeline (SD2/SD3)."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import httpx
from fastapi import Depends, FastAPI, Request

from . import __version__
from .analysis import AnalysisPipeline
from .config import Settings
from .models import AnalyseRequest, Feedback, Verdict


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = Settings.load()
    async with httpx.AsyncClient(timeout=settings.http_timeout) as http:
        app.state.pipeline = AnalysisPipeline(settings, http)
        yield


app = FastAPI(title="PhishGuard API", version=__version__, lifespan=lifespan)


def get_pipeline(request: Request) -> AnalysisPipeline:
    return request.app.state.pipeline


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "version": __version__}


@app.post("/analyse", response_model=Verdict, response_model_by_alias=True)
async def analyse(
    request: AnalyseRequest, pipeline: AnalysisPipeline = Depends(get_pipeline)
) -> Verdict:
    return await pipeline.run(request)


@app.post("/feedback", status_code=201)
def feedback(item: Feedback) -> dict[str, str]:
    return {"status": "received", "verdictId": item.verdict_id}
