from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="SIGNER_")

    bucket: str = "acumino-telemetry-staging"
    region: str = "us-east-1"
    url_ttl_seconds: int = 604800
    jwks_url: str = ""
    audience: str = "api://telemetry-signer"
    allowed_datasets: str = "telemetry,diagnostics,video"

    @property
    def datasets(self) -> set[str]:
        return {d.strip() for d in self.allowed_datasets.split(",") if d.strip()}


@lru_cache
def get_settings() -> Settings:
    return Settings()
