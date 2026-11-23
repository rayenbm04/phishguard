"""ReputationCache (SD3): remembers recent link results to save API quota."""

import time
from typing import Generic, TypeVar

T = TypeVar("T")


class ReputationCache(Generic[T]):
    """In-memory cache with a time limit. MongoDB can replace it later."""

    def __init__(self, ttl_seconds: float = 6 * 3600, max_items: int = 5000) -> None:
        self.ttl = ttl_seconds
        self.max_items = max_items
        self._items: dict[str, tuple[float, T]] = {}

    def get(self, key: str) -> T | None:
        hit = self._items.get(key)
        if hit is None:
            return None
        stored_at, value = hit
        if time.monotonic() - stored_at > self.ttl:
            del self._items[key]
            return None
        return value

    def put(self, key: str, value: T) -> None:
        if len(self._items) >= self.max_items:
            oldest = min(self._items, key=lambda k: self._items[k][0])
            del self._items[oldest]
        self._items[key] = (time.monotonic(), value)
