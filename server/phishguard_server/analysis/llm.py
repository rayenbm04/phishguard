"""Small JSON-only client for the LLM providers PhishGuard can use (LLM_PROVIDER in .env)."""

import json
import re
import time

import httpx


class LLMError(Exception):
    """The model gave no usable answer (missing key, timeout, quota, bad JSON)."""


# Free options: gemini (Google AI Studio free tier) and groq (free tier).
# Several models separated by commas: the next one is tried when one is busy (HTTP 503/429).
# "gemini-flash-latest" always points to Google's current Flash model.
DEFAULT_MODELS = {
    "gemini": "gemini-flash-latest,gemini-flash-lite-latest",
    # Groq retired the Llama 3 models in August 2026.
    "groq": "openai/gpt-oss-120b,openai/gpt-oss-20b",
    "anthropic": "claude-haiku-5-5",
    "openai": "gpt-4.1-mini",
}


RETRY_STATUS = {429, 500, 502, 503, 504}  # Busy or overloaded: try the next model.


def _error_detail(response: httpx.Response) -> str:
    try:
        body = response.json()
        error = body.get("error", body) if isinstance(body, dict) else body
        message = error.get("message", "") if isinstance(error, dict) else str(error)
    except ValueError:
        message = response.text
    return message.strip().replace("\n", " ")[:160]


def _parse_json(text: str) -> dict:
    text = text.strip()
    fenced = re.search(r"\{.*\}", text, re.DOTALL)  # Some models wrap JSON in ```json fences.
    try:
        data = json.loads(fenced.group(0) if fenced else text)
    except (json.JSONDecodeError, AttributeError) as exc:
        raise LLMError("the model did not return JSON") from exc
    if not isinstance(data, dict):
        raise LLMError("the model did not return a JSON object")
    return data


class LLMClient:
    def __init__(self, http: httpx.AsyncClient, provider: str, api_key: str, model: str = ""):
        self.http = http
        self.provider = provider.lower().strip() or "gemini"
        if self.provider not in DEFAULT_MODELS:
            raise ValueError(
                f"Unknown LLM_PROVIDER {provider!r}: use gemini, groq, anthropic or openai"
            )
        self.api_key = api_key
        names = model or DEFAULT_MODELS[self.provider]
        self.models = [m.strip() for m in names.split(",") if m.strip()]

    @property
    def model(self) -> str:
        return ", ".join(self.models)

    @property
    def enabled(self) -> bool:
        return bool(self.api_key)

    async def complete_json(self, system: str, user: str, timeout: float) -> dict:
        if not self.api_key:
            raise LLMError("LLM_API_KEY is not set")
        deadline = time.monotonic() + timeout
        errors: list[str] = []
        for i, model in enumerate(self.models):
            left = deadline - time.monotonic()
            if left < 0.8:
                errors.append(f"{model}: no time left")
                break
            # Keep some time for the next model if this one is busy.
            budget = left if i == len(self.models) - 1 else max(0.8, left * 0.6)
            try:
                response = await getattr(self, f"_{self.provider}")(model, system, user, budget)
            except httpx.TimeoutException:
                errors.append(f"{model}: timeout")
                continue
            except httpx.HTTPError as exc:
                raise LLMError(f"{self.provider} unreachable: {type(exc).__name__}") from exc
            if response.status_code in RETRY_STATUS:
                errors.append(f"{model}: HTTP {response.status_code} {_error_detail(response)}")
                continue
            if response.status_code != 200:
                raise LLMError(
                    f"{self.provider} {model} answered HTTP {response.status_code}: "
                    f"{_error_detail(response)}"
                )
            try:
                text = self._text(response.json())
            except (KeyError, IndexError, TypeError, ValueError) as exc:
                raise LLMError(f"unexpected {self.provider} answer") from exc
            return _parse_json(text)
        raise LLMError(f"{self.provider} busy: " + " | ".join(errors))

    def _text(self, body: dict) -> str:
        if self.provider == "gemini":
            return body["candidates"][0]["content"]["parts"][0]["text"]
        if self.provider == "anthropic":
            return "".join(b["text"] for b in body["content"] if b.get("type") == "text")
        return body["choices"][0]["message"]["content"]  # openai and groq

    async def _gemini(self, model: str, system: str, user: str, timeout: float) -> httpx.Response:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
        return await self.http.post(
            url,
            headers={"x-goog-api-key": self.api_key},
            json={
                "systemInstruction": {"parts": [{"text": system}]},
                "contents": [{"role": "user", "parts": [{"text": user}]}],
                "generationConfig": {
                    "temperature": 0.2,
                    "maxOutputTokens": 700,
                    "responseMimeType": "application/json",
                },
            },
            timeout=timeout,
        )

    async def _anthropic(
        self, model: str, system: str, user: str, timeout: float
    ) -> httpx.Response:
        return await self.http.post(
            "https://api.anthropic.com/v1/messages",
            headers={"x-api-key": self.api_key, "anthropic-version": "2023-06-01"},
            json={
                "model": model,
                "max_tokens": 700,
                "temperature": 0.2,
                "system": system,
                "messages": [{"role": "user", "content": user}],
            },
            timeout=timeout,
        )

    async def _groq(self, model: str, system: str, user: str, timeout: float) -> httpx.Response:
        # Groq speaks the OpenAI format.
        return await self._openai(
            model, system, user, timeout, url="https://api.groq.com/openai/v1/chat/completions"
        )

    async def _openai(
        self,
        model: str,
        system: str,
        user: str,
        timeout: float,
        url: str = "https://api.openai.com/v1/chat/completions",
    ) -> httpx.Response:
        body: dict = {
            "model": model,
            "temperature": 0.2,
            "max_tokens": 700,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        }
        if "gpt-oss" in model:
            # Reasoning model: think briefly, and leave room for the answer after the thinking.
            body["reasoning_effort"] = "low"
            body["max_tokens"] = 2000
        return await self.http.post(
            url, headers={"Authorization": f"Bearer {self.api_key}"}, json=body, timeout=timeout
        )
