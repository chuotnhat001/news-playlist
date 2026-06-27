from datetime import datetime, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import async_session, get_db
from app.models import Article, Category
from app.routers.categories import require_api_key
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
    status: str
    message: str


@router.get("/articles", response_model=list[ArticleResponse])
async def get_articles(
    category_id: str,
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    category = await db.get(Category, category_id)
    if not category:
        raise HTTPException(404, "Category not found")

    stmt = (
        select(Article)
        .where(Article.category_id == category_id)
        .order_by(Article.published_at.desc())
        .limit(limit)
        .offset(offset)
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


async def _do_refresh(category_id: str):
    async with async_session() as db:
        category = await db.get(Category, category_id)
        if category:
            await crawl_and_store(category, db)
            category.last_crawled_at = datetime.now(timezone.utc)
            await db.commit()


@router.post(
    "/refresh",
    response_model=RefreshResponse,
    status_code=202,
    dependencies=[Depends(require_api_key)],
)
async def refresh_category(
    category_id: str,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    category = await db.get(Category, category_id)
    if not category:
        raise HTTPException(404, "Category not found")

    if category.last_crawled_at:
        elapsed = (datetime.now(timezone.utc) - category.last_crawled_at).total_seconds()
        if elapsed < 300:
            raise HTTPException(
                429, f"Rate limited. Try again in {int(300 - elapsed)}s"
            )

    background_tasks.add_task(_do_refresh, category_id)

    return RefreshResponse(
        status="queued",
        message=f"Refresh queued for {category.name}",
    )
