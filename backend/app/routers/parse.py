from fastapi import APIRouter, Depends, HTTPException, Request

from ..models.recipe import Recipe
from ..models.requests import ParseRequest
from ..services.pipeline import ParsePipeline

router = APIRouter()


def get_pipeline() -> ParsePipeline:
    return ParsePipeline()


@router.post("/parse", response_model=Recipe)
async def parse_recipe(
    body: ParseRequest,
    req: Request,
    pipeline: ParsePipeline = Depends(get_pipeline),
) -> Recipe:
    if not body.url and not body.text and not body.image_base64:
        raise HTTPException(status_code=422, detail="Provide url, text, or image_base64")
    return await pipeline.run(body, http_client=req.app.state.http_client)


@router.get("/health")
async def health() -> dict:
    return {"status": "ok"}
