from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient

from telemetry_signer.app import app, s3_client
from telemetry_signer.auth import require_token


@pytest.fixture
def client():
    s3 = MagicMock()
    s3.generate_presigned_url.return_value = "https://example.invalid/presigned"
    app.dependency_overrides[require_token] = lambda: {"sub": "robot-1", "tenant": "acme"}
    app.dependency_overrides[s3_client] = lambda: s3
    yield TestClient(app), s3
    app.dependency_overrides.clear()


def test_healthz(client):
    c, _ = client
    assert c.get("/healthz").json() == {"status": "ok"}


def test_issues_url(client):
    c, s3 = client
    resp = c.post(
        "/v1/uploads",
        json={"tenant": "acme", "site": "rtm-01", "dataset": "telemetry", "filename": "a.tar"},
    )
    assert resp.status_code == 200
    assert resp.json()["key"] == "acme/rtm-01/telemetry/a.tar"
    s3.generate_presigned_url.assert_called_once()


def test_rejects_unknown_dataset(client):
    c, _ = client
    resp = c.post(
        "/v1/uploads",
        json={"tenant": "acme", "site": "rtm-01", "dataset": "secrets", "filename": "a.tar"},
    )
    assert resp.status_code == 400


def test_requires_token():
    c = TestClient(app)
    resp = c.post(
        "/v1/uploads",
        json={"tenant": "acme", "site": "rtm-01", "dataset": "telemetry", "filename": "a.tar"},
    )
    assert resp.status_code == 401
