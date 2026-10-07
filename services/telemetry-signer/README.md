# telemetry-signer

Issues short-lived S3 presigned `PUT` URLs so edge sites can upload telemetry
bundles directly to the telemetry bucket without holding bucket credentials.

## API

### `POST /v1/uploads`

```http
Authorization: Bearer <access-token>
Content-Type: application/json
```

```json
{
  "tenant": "acme-logistics",
  "site": "rotterdam-01",
  "dataset": "telemetry",
  "filename": "2026-10-01T12-00-00Z.tar.zst"
}
```

Response:

```json
{
  "url": "https://...",
  "key": "acme-logistics/rotterdam-01/telemetry/2026-10-01T12-00-00Z.tar.zst",
  "expiresAt": "2026-10-08T12:00:00Z"
}
```

### `GET /healthz`

Liveness/readiness probe.

## Configuration

| Variable | Default | Description |
|---|---|---|
| `SIGNER_BUCKET` | — | Target S3 bucket |
| `SIGNER_REGION` | `us-east-1` | Bucket region |
| `SIGNER_URL_TTL_SECONDS` | `604800` | Presigned URL lifetime |
| `SIGNER_JWKS_URL` | — | JWKS endpoint of the identity provider |
| `SIGNER_AUDIENCE` | `api://telemetry-signer` | Expected token audience |
| `SIGNER_ALLOWED_DATASETS` | `telemetry,diagnostics,video` | Accepted dataset names |

## Development

```bash
uv sync
uv run pytest
uv run uvicorn telemetry_signer.app:app --reload
```
