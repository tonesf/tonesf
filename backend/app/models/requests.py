from typing import Optional

from pydantic import BaseModel


class ParseRequest(BaseModel):
    url: Optional[str] = None
    text: Optional[str] = None
    image_base64: Optional[str] = None
    image_media_type: Optional[str] = "image/jpeg"
