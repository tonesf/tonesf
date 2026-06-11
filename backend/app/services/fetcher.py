from __future__ import annotations

import re
from dataclasses import dataclass, field

import httpx
from bs4 import BeautifulSoup
from fastapi import HTTPException

MOBILE_UA = (
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
)
DESKTOP_UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)

_INSTAGRAM_RE = re.compile(r"instagram\.com/(p|reel|tv)/", re.IGNORECASE)


@dataclass
class RawContent:
    text: str = ""
    media_urls: list[str] = field(default_factory=list)
    source_url: str = ""
    source_platform: str = "web"
    schema_org_json: str | None = None


def is_instagram_url(url: str) -> bool:
    return bool(_INSTAGRAM_RE.search(url))


async def fetch_url(url: str, client: httpx.AsyncClient) -> RawContent:
    if is_instagram_url(url):
        return await _fetch_instagram(url, client)
    return await _fetch_generic(url, client)


async def _fetch_instagram(url: str, client: httpx.AsyncClient) -> RawContent:
    try:
        resp = await client.get(url, headers={"User-Agent": MOBILE_UA}, follow_redirects=True)
        resp.raise_for_status()
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Could not fetch Instagram URL: {exc}")

    soup = BeautifulSoup(resp.text, "lxml")
    og: dict[str, str] = {}
    for tag in soup.find_all("meta"):
        prop = tag.get("property") or tag.get("name") or ""
        content = tag.get("content", "")
        if prop.startswith("og:") or prop.startswith("twitter:"):
            og[prop] = content

    caption = og.get("og:description", "") or og.get("twitter:description", "")
    title = og.get("og:title", "") or og.get("twitter:title", "")
    combined_text = f"{title}\n{caption}".strip()

    media: list[str] = []
    for key in ("og:video:secure_url", "og:video", "og:image"):
        if og.get(key):
            media.append(og[key])

    return RawContent(
        text=combined_text,
        media_urls=media,
        source_url=url,
        source_platform="instagram",
    )


async def _fetch_generic(url: str, client: httpx.AsyncClient) -> RawContent:
    try:
        resp = await client.get(url, headers={"User-Agent": DESKTOP_UA}, follow_redirects=True)
        resp.raise_for_status()
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Could not fetch URL: {exc}")

    from .extractor import extract_content

    return extract_content(resp.text, source_url=url)
