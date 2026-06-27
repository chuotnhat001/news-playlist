import logging
from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select, text

from app.config import settings
from app.database import async_session, get_db, init_db
from app.models import Category
from app.routers import articles, categories
from app.services.crawl_service import refresh_all_categories

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    await seed_default_categories()
    scheduler.add_job(
        refresh_all_categories,
        "interval",
        minutes=settings.crawl_interval_minutes,
        max_instances=1,
        misfire_grace_time=60,
    )
    scheduler.start()
    logger.info(
        f"Scheduler started — refreshing every {settings.crawl_interval_minutes} min"
    )
    await refresh_all_categories()
    yield
    scheduler.shutdown()


async def seed_default_categories():
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

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins.split(","),
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["*"],
)

app.include_router(categories.router)
app.include_router(articles.router)


@app.get("/health")
async def health():
    try:
        async with async_session() as db:
            await db.execute(text("SELECT 1"))
        return {"status": "ok", "db": "ok"}
    except Exception as e:
        return {"status": "degraded", "db": str(e)}
