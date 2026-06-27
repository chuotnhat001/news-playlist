from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    api_key: str = ""
    crawl_interval_minutes: int = 30
    crawl_delay_seconds: float = 0.5
    max_articles_per_category: int = 10
    allowed_origins: str = "*"

    model_config = {"env_prefix": "NP_"}


settings = Settings()
