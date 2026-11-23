"""Small JSON-only client for the LLM providers PhishGuard can use (LLM_PROVIDER in .env)."""

import json
import re

import httpx


class LLMError(Exception):
    """The model gave no usable answer (missing key, timeout, quota, bad JSON)."""


DEFAULT_MODELS = {
    "gemini": "gemini-2.5-flash",
    "anthropic": "claude-haiku-5-5",
    "openai": "gpt-4.1-mini",
}


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
            raise ValueError(f"Unknown LLM_PROVIDER {provider!r}: use gemini, anthropic or openai")
        self.api_key = api_key
        self.model = model or DEFAULT_MODELS[self.provider]

    @property
    def enabled(self) -> bool:
        return bool(self.api_key)

    async def complete_json(self, system: str, user: str, timeout: float) -> dict:
        if not self.api_key:
            raise LLMError("LLM_API_KEY is not set")
        try:
            response = await getattr(self, f"_{self.provider}")(system, user, timeout)
        except httpx.HTTPError as exc:
            raise LLMError(f"{self.provider} unreachable: {type(exc).__name__}") from exc
        if response.status_code != 200:
            raise LLMError(f"{self.provider} answered HTTP {response.status_code}")
        try:
            text = self._text(response.json())
        except (KeyError, IndexError, TypeError, ValueError) as exc:
            raise LLMError(f"unexpected {self.provider} answer") from exc
        return _parse_json(text)

    def _text(self, body: dict) -> str:
        if self.provider == "gemini":
            return body["candidates"][0]["content"]["parts"][0]["text"]
        if self.provider == "anthropic":
            return "".join(b["text"] for b in body["content"] if b.get("type") == "text")
        return body["choices"][0]["message"]["content"]

    async def _gemini(self, system: str, user: str, timeout: float) -> httpx.Response:
        url = (
            f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent"
        )
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

    async def _anthropic(self, system: str, user: str, timeout: float) -> httpx.Response:
        return await self.http.post(
            "https://api.anthropic.com/v1/messages",
            headers={"x-api-key": self.api_key, "anthropic-version": "2023-06-01"},
            json={
                "model": self.model,
                "max_tokens": 700,
                "temperature": 0.2,
                "system": system,
                "messages": [{"role": "user", "content": user}],
            },
            timeout=timeout,
        )

    async def _openai(self, system: str, user: str, timeout: float) -> httpx.Response:
        return await self.http.post(
            "https://api.openai.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json={
                "model": self.model,
                "temperature": 0.2,
                "max_tokens": 700,
                "response_format": {"type": "json_object"},
                "messages": [
                    {"role": "system", "content": system},
                    {"role": "user", "content": user},
                ],
            },
            timeout=timeout,
        )
