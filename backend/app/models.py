from datetime import datetime

from sqlalchemy import DateTime, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    url: Mapped[str] = mapped_column(Text, nullable=False)
    source: Mapped[str] = mapped_column(String(50), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )


class Article(Base):
    __tablename__ = "articles"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    source: Mapped[str] = mapped_column(String(50), nullable=False)
    audio_url: Mapped[str] = mapped_column(Text, nullable=False)
    article_url: Mapped[str] = mapped_column(Text, nullable=False)
    category_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    published_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    crawled_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
