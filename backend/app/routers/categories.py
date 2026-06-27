from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Article, Category

router = APIRouter(prefix="/api/categories", tags=["categories"])


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
    stmt = select(Category)
    result = await db.execute(stmt)
    categories = result.scalars().all()

    response = []
    for cat in categories:
        count_stmt = select(func.count()).where(Article.category_id == cat.id)
        count_result = await db.execute(count_stmt)
        count = count_result.scalar() or 0
        response.append(
            CategoryResponse(
                id=cat.id,
                name=cat.name,
                url=cat.url,
                source=cat.source,
                article_count=count,
            )
        )
    return response


@router.post("", response_model=CategoryResponse, status_code=201)
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


@router.delete("/{category_id}", status_code=204)
async def delete_category(
    category_id: str, db: AsyncSession = Depends(get_db)
):
    category = await db.get(Category, category_id)
    if not category:
        raise HTTPException(404, "Category not found")

    await db.delete(category)
    await db.commit()
