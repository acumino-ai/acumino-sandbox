"""Edge telemetry agent.

Watches SPOOL_DIR for telemetry bundles dropped by robots, requests a presigned
upload URL from telemetry-signer and uploads each bundle to S3. Bundles are
deleted after a successful upload; failures are retried on the next cycle.
"""

import json
import logging
import os
import time
import urllib.parse
import urllib.request
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("telemetry-agent")

SITE_ID = os.environ["SITE_ID"]
TENANT = os.environ["TENANT"]
SIGNER_URL = os.environ["SIGNER_URL"]
SPOOL_DIR = Path(os.environ.get("SPOOL_DIR", "/spool"))
INTERVAL = int(os.environ.get("INTERVAL_SECONDS", "60"))
DATASETS = os.environ.get("DATASETS", "telemetry").split(",")


def get_token() -> str:
    data = urllib.parse.urlencode(
        {
            "grant_type": "client_credentials",
            "client_id": os.environ["OIDC_CLIENT_ID"],
            "client_secret": os.environ["OIDC_CLIENT_SECRET"],
            "scope": "api://telemetry-signer/.default",
        }
    ).encode()
    with urllib.request.urlopen(os.environ["OIDC_TOKEN_URL"], data=data, timeout=10) as resp:
        return json.load(resp)["access_token"]


def upload(bundle: Path, dataset: str, token: str) -> None:
    body = json.dumps(
        {"tenant": TENANT, "site": SITE_ID, "dataset": dataset, "filename": bundle.name}
    ).encode()
    req = urllib.request.Request(
        SIGNER_URL,
        data=body,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        url = json.load(resp)["url"]

    put = urllib.request.Request(url, data=bundle.read_bytes(), method="PUT")
    with urllib.request.urlopen(put, timeout=300):
        pass


def cycle() -> None:
    bundles = [
        (p, ds) for ds in DATASETS for p in sorted((SPOOL_DIR / ds).glob("*")) if p.is_file()
    ]
    if not bundles:
        log.info("site=%s tenant=%s spool empty", SITE_ID, TENANT)
        return

    token = get_token()
    for bundle, dataset in bundles:
        upload(bundle, dataset, token)
        bundle.unlink()
        log.info("uploaded %s/%s", dataset, bundle.name)


def main() -> None:
    for ds in DATASETS:
        (SPOOL_DIR / ds).mkdir(parents=True, exist_ok=True)
    log.info("starting site=%s tenant=%s signer=%s", SITE_ID, TENANT, SIGNER_URL)
    while True:
        try:
            cycle()
        except Exception as exc:  # retry on next cycle
            log.warning("cycle failed: %s", exc)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
