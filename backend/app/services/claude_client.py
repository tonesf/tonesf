from __future__ import annotations

import json

import anthropic
from fastapi import HTTPException

from ..config import settings
from ..models.recipe import Recipe
from .fetcher import RawContent

RECIPE_SYSTEM_PROMPT = """\
You are a recipe extraction assistant. Extract structured recipe data from any input — raw HTML, social media caption, plain text, or schema.org JSON-LD.

Output ONLY valid JSON matching this exact schema. Do not wrap in markdown fences or add commentary outside the JSON.

{
  "title": "string (required)",
  "description": "string or null",
  "ingredients": [
    {
      "quantity": number or null,
      "quantity_max": number or null,
      "unit": "string or null — use FULL English unit names: cup, tablespoon, teaspoon, fluid ounce, ounce, pound, gram, kilogram, milliliter, liter — NEVER abbreviations",
      "unit_system": "imperial | metric | universal",
      "name": "string (required) — ingredient name only, no quantities or prep notes",
      "preparation": "string or null — e.g. finely chopped, sifted",
      "optional": boolean
    }
  ],
  "steps": [
    {
      "index": integer starting at 1,
      "instruction": "string — one clear action per step",
      "duration_minutes": integer or null,
      "temperature_f": number or null — always in Fahrenheit regardless of source unit,
      "media_urls": []
    }
  ],
  "media": [],
  "metadata": {
    "source_url": "string or null",
    "source_platform": "string or null",
    "servings": integer or null,
    "servings_unit": "servings",
    "prep_time_minutes": integer or null,
    "cook_time_minutes": integer or null,
    "total_time_minutes": integer or null,
    "cuisine": "string or null",
    "meal_type": "breakfast | lunch | dinner | snack | dessert | beverage | null",
    "difficulty": "easy | medium | hard | null",
    "tags": []
  }
}

Rules:
1. NEVER invent ingredients or steps not present in the source.
2. Split combined steps into atomic steps — one clear action per step.
3. Always store temperatures in Fahrenheit (convert from Celsius if needed).
4. For ranges like "2-3 cups", set quantity=2, quantity_max=3.
5. For "to taste" or "as needed", set quantity=null and unit=null.
6. Separate the ingredient name from preparation notes.
7. If input is clearly not a recipe, return exactly: {"error": "not_a_recipe"}
"""


class ClaudeClient:
    def __init__(self) -> None:
        self._client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

    async def parse_recipe(self, raw: RawContent) -> Recipe:
        messages = [{"role": "user", "content": self._build_user_content(raw)}]

        response = await self._client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=4096,
            system=RECIPE_SYSTEM_PROMPT,
            messages=messages,
        )

        text = response.content[0].text.strip()
        # Strip accidental markdown fences
        if text.startswith("```"):
            text = text.split("\n", 1)[1]
            text = text.rsplit("```", 1)[0].strip()

        try:
            data = json.loads(text)
        except json.JSONDecodeError as exc:
            raise HTTPException(status_code=502, detail=f"Claude returned invalid JSON: {exc}")

        if "error" in data:
            raise HTTPException(status_code=422, detail=data["error"])

        try:
            return Recipe(**data)
        except Exception as exc:
            raise HTTPException(status_code=502, detail=f"Recipe validation failed: {exc}")

    def _build_user_content(self, raw: RawContent) -> list | str:
        parts: list[dict] = []

        if raw.schema_org_json:
            parts.append({
                "type": "text",
                "text": (
                    "I found this schema.org Recipe JSON-LD embedded in the page — "
                    "use it as the primary source:\n\n"
                    f"{raw.schema_org_json}\n\n"
                    "Additional page text follows:\n"
                    f"{raw.text}"
                ),
            })
        elif raw.text:
            prefix = ""
            if raw.source_platform == "instagram":
                prefix = "This is an Instagram post caption and title:\n\n"
            parts.append({"type": "text", "text": prefix + raw.text})

        if not parts:
            raise HTTPException(status_code=422, detail="No content to parse")

        # Add source metadata hint
        meta_hint = f"\n\nSource URL: {raw.source_url}" if raw.source_url else ""
        meta_hint += f"\nPlatform: {raw.source_platform}" if raw.source_platform else ""
        if meta_hint:
            parts[-1]["text"] += meta_hint

        return parts if len(parts) > 1 else parts[0]["text"]
