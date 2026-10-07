import logging
from datetime import UTC, datetime, timedelta

import boto3
from fastapi import Depends, FastAPI, HTTPException, status
from pydantic import BaseModel

from telemetry_signer.auth import require_token
from telemetry_signer.config import Settings, get_settings

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("telemetry_signer")

app = FastAPI(title="telemetry-signer")


class UploadRequest(BaseModel):
    tenant: str
    site: str
    dataset: str
    filename: str


class UploadResponse(BaseModel):
    url: str
    key: str
    expiresAt: str


def s3_client(settings: Settings = Depends(get_settings)):
    return boto3.client("s3", region_name=settings.region)


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.post("/v1/uploads", response_model=UploadResponse)
def create_upload(
    req: UploadRequest,
    claims: dict = Depends(require_token),
    settings: Settings = Depends(get_settings),
    s3=Depends(s3_client),
) -> UploadResponse:
    if req.dataset not in settings.datasets:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"unknown dataset {req.dataset!r}")

    key = f"{req.tenant}/{req.site}/{req.dataset}/{req.filename}"
    url = s3.generate_presigned_url(
        "put_object",
        Params={"Bucket": settings.bucket, "Key": key},
        ExpiresIn=settings.url_ttl_seconds,
    )
    expires_at = datetime.now(UTC) + timedelta(seconds=settings.url_ttl_seconds)

    log.info("issued upload url sub=%s key=%s url=%s", claims.get("sub"), key, url)
    return UploadResponse(url=url, key=key, expiresAt=expires_at.isoformat())
