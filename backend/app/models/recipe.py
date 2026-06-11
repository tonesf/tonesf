from __future__ import annotations

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field, model_validator


class UnitSystem(str, Enum):
    IMPERIAL = "imperial"
    METRIC = "metric"
    UNIVERSAL = "universal"


class Ingredient(BaseModel):
    quantity: Optional[float] = None
    quantity_max: Optional[float] = None
    unit: Optional[str] = None
    unit_system: UnitSystem = UnitSystem.UNIVERSAL
    name: str
    preparation: Optional[str] = None
    optional: bool = False

    @model_validator(mode="before")
    @classmethod
    def coerce_quantity(cls, data: dict) -> dict:
        for key in ("quantity", "quantity_max"):
            val = data.get(key)
            if isinstance(val, str):
                try:
                    data[key] = float(val)
                except ValueError:
                    data[key] = None
        return data


class Step(BaseModel):
    index: int
    instruction: str
    duration_minutes: Optional[int] = None
    temperature_f: Optional[float] = None
    media_urls: list[str] = Field(default_factory=list)


class MediaItem(BaseModel):
    url: str
    type: str  # "image" | "video"
    caption: Optional[str] = None
    width: Optional[int] = None
    height: Optional[int] = None


class RecipeMetadata(BaseModel):
    source_url: Optional[str] = None
    source_platform: Optional[str] = None
    servings: Optional[int] = None
    servings_unit: str = "servings"
    prep_time_minutes: Optional[int] = None
    cook_time_minutes: Optional[int] = None
    total_time_minutes: Optional[int] = None
    cuisine: Optional[str] = None
    meal_type: Optional[str] = None
    difficulty: Optional[str] = None
    tags: list[str] = Field(default_factory=list)


class Recipe(BaseModel):
    title: str
    description: Optional[str] = None
    ingredients: list[Ingredient]
    steps: list[Step]
    media: list[MediaItem] = Field(default_factory=list)
    metadata: RecipeMetadata
