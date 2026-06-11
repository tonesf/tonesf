from __future__ import annotations

import json
import re

from bs4 import BeautifulSoup

from .fetcher import RawContent

_NOISE_TAGS = {"nav", "footer", "header", "aside", "script", "style", "noscript"}


def extract_content(html: str, source_url: str = "") -> RawContent:
    soup = BeautifulSoup(html, "lxml")

    # 1. Try schema.org Recipe JSON-LD — highest quality signal
    schema_json = _extract_schema_org(soup)
    if schema_json:
        text = _schema_org_to_text(schema_json)
        media = _collect_media(soup)
        return RawContent(
            text=text,
            media_urls=media,
            source_url=source_url,
            source_platform="web",
            schema_org_json=json.dumps(schema_json),
        )

    # 2. Fallback: strip noise, extract body text
    for tag in soup.find_all(_NOISE_TAGS):
        tag.decompose()
    body_text = soup.get_text(separator="\n", strip=True)
    body_text = re.sub(r"\n{3,}", "\n\n", body_text)

    og_image = ""
    og_tag = soup.find("meta", property="og:image")
    if og_tag:
        og_image = og_tag.get("content", "")

    return RawContent(
        text=body_text[:8000],  # cap token cost
        media_urls=[og_image] if og_image else [],
        source_url=source_url,
        source_platform="web",
    )


def _extract_schema_org(soup: BeautifulSoup) -> dict | None:
    for tag in soup.find_all("script", type="application/ld+json"):
        try:
            raw = tag.string or ""
            data = json.loads(raw)
        except (json.JSONDecodeError, AttributeError):
            continue

        items = data if isinstance(data, list) else [data]
        for item in items:
            if isinstance(item, dict):
                # Handle @graph arrays
                if item.get("@type") == "Recipe":
                    return item
                for node in item.get("@graph", []):
                    if isinstance(node, dict) and node.get("@type") == "Recipe":
                        return node
    return None


def _schema_org_to_text(data: dict) -> str:
    """Convert schema.org Recipe dict to a text blob for Claude."""
    lines: list[str] = []
    if name := data.get("name"):
        lines.append(f"Recipe: {name}")
    if desc := data.get("description"):
        lines.append(f"Description: {desc}")

    ingredients: list = data.get("recipeIngredient", [])
    if ingredients:
        lines.append("\nIngredients:")
        for ing in ingredients:
            lines.append(f"- {ing}")

    instructions = data.get("recipeInstructions", [])
    if instructions:
        lines.append("\nInstructions:")
        for i, step in enumerate(instructions, 1):
            if isinstance(step, str):
                lines.append(f"{i}. {step}")
            elif isinstance(step, dict):
                lines.append(f"{i}. {step.get('text', '')}")

    for key, label in [
        ("recipeYield", "Yield"),
        ("prepTime", "Prep time"),
        ("cookTime", "Cook time"),
        ("totalTime", "Total time"),
        ("recipeCuisine", "Cuisine"),
        ("recipeCategory", "Category"),
    ]:
        if val := data.get(key):
            lines.append(f"{label}: {val}")

    return "\n".join(lines)


def _collect_media(soup: BeautifulSoup) -> list[str]:
    urls: list[str] = []
    og_tag = soup.find("meta", property="og:image")
    if og_tag:
        urls.append(og_tag.get("content", ""))
    og_video = soup.find("meta", property="og:video")
    if og_video:
        urls.append(og_video.get("content", ""))
    return [u for u in urls if u]
