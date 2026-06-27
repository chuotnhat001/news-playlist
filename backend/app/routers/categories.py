from fastapi import APIRouter, Depends, HTTPException, Query, Security
from fastapi.security import APIKeyHeader
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models import Article, Category

router = APIRouter(prefix="/api/categories", tags=["categories"])

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


async def require_api_key(key: str | None = Security(api_key_header)):
    if not settings.api_key:
        return
    if key != settings.api_key:
        raise HTTPException(401, "Invalid or missing API key")


class CategoryResponse(BaseModel):
    id: str
    name: str
    url: str
    source: str
    article_count: int = 0

    model_config = {"from_attributes": True}


class CategoryCreate(BaseModel):
    name: str
    url: str


@router.get("", response_model=list[CategoryResponse])
async def get_categories(db: AsyncSession = Depends(get_db)):
    stmt = (
        select(Category, func.count(Article.id).label("article_count"))
        .outerjoin(Article, Article.category_id == Category.id)
        .group_by(Category.id)
    )
    result = await db.execute(stmt)
    rows = result.all()

    return [
        CategoryResponse(
            id=cat.id,
            name=cat.name,
            url=cat.url,
            source=cat.source,
            article_count=count,
        )
        for cat, count in rows
    ]


@router.post(
    "",
    response_model=CategoryResponse,
    status_code=201,
    dependencies=[Depends(require_api_key)],
)
async def create_category(
    body: CategoryCreate, db: AsyncSession = Depends(get_db)
):
    url = body.url.strip()
    name = body.name.strip()

    if not url.startswith("https://"):
        raise HTTPException(400, "URL must start with https://")

    if "soha.vn" in url:
        source = "soha"
    elif "dantri.com.vn" in url:
        source = "dantri"
    else:
        raise HTTPException(400, "Only soha.vn and dantri.com.vn are supported")

    cat_id = f"{source}_{name.lower().replace(' ', '-')}"

    existing = await db.get(Category, cat_id)
    if existing:
        raise HTTPException(409, f"Category '{name}' already exists")

    category = Category(id=cat_id, name=name, url=url, source=source)
    db.add(category)
    await db.commit()

    return CategoryResponse(
        id=category.id,
        name=category.name,
        url=category.url,
        source=category.source,
        article_count=0,
    )


@router.delete(
    "/{category_id}",
    status_code=204,
    dependencies=[Depends(require_api_key)],
)
async def delete_category(
    category_id: str, db: AsyncSession = Depends(get_db)
):
    category = await db.get(Category, category_id)
    if not category:
        raise HTTPException(404, "Category not found")

    await db.delete(category)
    await db.commit()
