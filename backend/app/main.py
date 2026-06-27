import logging
from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI

from app.config import settings
from app.database import async_session, init_db
from app.models import Category
from app.routers import articles, categories
from app.services.crawl_service import refresh_all_categories

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


async def scheduled_refresh():
    async with async_session() as db:
        await refresh_all_categories(db)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    await seed_default_categories()
    scheduler.add_job(
        scheduled_refresh,
        "interval",
        minutes=settings.crawl_interval_minutes,
    )
    scheduler.start()
    logger.info(
        f"Scheduler started — refreshing every {settings.crawl_interval_minutes} min"
    )
    # Run initial refresh
    await scheduled_refresh()
    yield
    scheduler.shutdown()


async def seed_default_categories():
    from sqlalchemy import select

    async with async_session() as db:
        result = await db.execute(select(Category))
        if result.scalars().first():
            return

        defaults = [
            Category(
                id="soha_quoc-te",
                name="Quốc Tế",
                url="https://soha.vn/quoc-te.htm",
                source="soha",
            ),
            Category(
                id="dantri_the-gioi",
                name="Thế Giới",
                url="https://dantri.com.vn/the-gioi.htm",
                source="dantri",
            ),
            Category(
                id="soha_cong-nghe",
                name="Công Nghệ",
                url="https://soha.vn/cong-nghe.htm",
                source="soha",
            ),
        ]
        for cat in defaults:
            db.add(cat)
        await db.commit()
        logger.info("Seeded default categories")


app = FastAPI(
    title="News Playlist API",
    description="Backend API for Vietnamese news audio playlist",
    version="0.1.0",
    lifespan=lifespan,
)

app.include_router(categories.router)
app.include_router(articles.router)


@app.get("/health")
async def health():
    return {"status": "ok"}
