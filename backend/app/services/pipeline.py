from __future__ import annotations

import httpx

from ..models.recipe import Recipe
from ..models.requests import ParseRequest
from .claude_client import ClaudeClient
from .fetcher import RawContent, fetch_url


class ParsePipeline:
    def __init__(self) -> None:
        self._claude = ClaudeClient()

    async def run(self, request: ParseRequest, http_client: httpx.AsyncClient) -> Recipe:
        raw = await self._build_raw_content(request, http_client)
        return await self._claude.parse_recipe(raw)

    async def _build_raw_content(
        self, request: ParseRequest, http_client: httpx.AsyncClient
    ) -> RawContent:
        if request.url:
            raw = await fetch_url(request.url, http_client)
            # Append any extra text the caller provided
            if request.text:
                raw.text = f"{raw.text}\n\n{request.text}".strip()
            return raw

        if request.text:
            return RawContent(text=request.text, source_platform="manual")

        # image_base64 path — delegate entirely to Claude vision
        return RawContent(
            text="",
            source_platform="image",
        )
