# telemetry-agent

Runs on each edge site cluster. Watches the spool directory for telemetry bundles
dropped by robots (`/spool/<dataset>/`), gets an upload URL from `telemetry-signer`
and uploads each bundle to S3. Deployed by the `edge-telemetry-agent` ApplicationSet.

Standard library only, no dependencies.

```bash
docker build -t telemetry-agent services/telemetry-agent
```
