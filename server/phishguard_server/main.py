"""FastAPI entry point. Step 1: the contract is real, the analysis is a placeholder."""

from datetime import datetime, timezone
from uuid import uuid4

from fastapi import FastAPI

from . import __version__
from .models import Advice, AnalyseRequest, Feedback, Reason, Verdict, VerdictLevel

app = FastAPI(title="PhishGuard API", version=__version__)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "version": __version__}


@app.post("/analyse", response_model=Verdict, response_model_by_alias=True)
def analyse(request: AnalyseRequest) -> Verdict:
    # Placeholder until the pipeline (step 3): never answer SAFE without evidence.
    return Verdict(
        id=str(uuid4()),
        level=VerdictLevel.UNSURE,
        risk_score=50,
        summary="The analysis is not available yet.",
        checked_at=datetime.now(timezone.utc),
        reasons=[
            Reason(
                rank=1,
                text="No check has been run on this message yet.",
                evidence_source="PhishGuard",
            )
        ],
        advice=[Advice(action="Do not open the link until the check is available.")],
    )


@app.post("/feedback", status_code=201)
def feedback(item: Feedback) -> dict[str, str]:
    return {"status": "received", "verdictId": item.verdict_id}
