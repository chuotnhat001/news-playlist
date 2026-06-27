from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Article, Category
from app.services.crawl_service import crawl_and_store

router = APIRouter(prefix="/api", tags=["articles"])


class ArticleResponse(BaseModel):
    id: str
    title: str
    source: str
    audio_url: str
    article_url: str
    published_at: str

    model_config = {"from_attributes": True}


class RefreshResponse(BaseModel):
    articles_found: int
    no_audio_count: int
    errors: list[str]


@router.get("/articles", response_model=list[ArticleResponse])
async def get_articles(
    category_id: str, db: AsyncSession = Depends(get_db)
):
    stmt = (
        select(Article)
        .where(Article.category_id == category_id)
        .order_by(Article.published_at.desc())
        .limit(20)
    )
    result = await db.execute(stmt)
    articles = result.scalars().all()

    return [
        ArticleResponse(
            id=a.id,
            title=a.title,
            source=a.source,
            audio_url=a.audio_url,
            article_url=a.article_url,
            published_at=a.published_at.isoformat(),
        )
        for a in articles
    ]


@router.post("/refresh", response_model=RefreshResponse)
async def refresh_category(
    category_id: str, db: AsyncSession = Depends(get_db)
):
    category = await db.get(Category, category_id)
    if not category:
        raise HTTPException(404, "Category not found")

    result = await crawl_and_store(category, db)

    return RefreshResponse(
        articles_found=len(result.articles),
        no_audio_count=result.no_audio_count,
        errors=result.errors,
    )
