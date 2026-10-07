# acumino-sandbox

Platform monorepo for the Acumino telemetry pipeline: robots at customer sites
produce telemetry bundles, an agent on the site's edge cluster uploads them to
S3 through the `telemetry-signer` service running on EKS. Everything is
delivered with Argo CD.

```
robots ──► edge cluster (k3s, per site)          AWS (EKS prod)
           ├─ telemetry-agent ──── token ────►   telemetry-signer ──► presigned URL
           │        └──────────── PUT bundle ─────────────────────────► S3 telemetry bucket
           └─ fluent-bit ──────── logs ───────►  CloudWatch Logs
                    ▲
                    └──────── deploys ─────────  Argo CD (prod) ── ApplicationSets
```

## Layout

| Path | What |
|---|---|
| `services/telemetry-signer/` | Python service that issues presigned S3 upload URLs |
| `services/telemetry-agent/` | Edge agent that uploads telemetry bundles via the signer |
| `charts/telemetry-signer/` | Helm chart for the service (published to ECR as OCI) |
| `gitops/clusters/cloud-<env>/` | Argo CD root app (`root.yaml`) and the Applications it manages (`apps/`) |
| `gitops/values/` | Helm values per app and environment (`common.yaml` + `<env>.yaml`) |
| `gitops/manifests/` | Plain manifests synced by Argo CD (e.g. network policies) |
| `gitops/edge/` | Manifests deployed to every edge site by the prod ApplicationSets |
| `infra/terraform/` | AWS infrastructure: EKS, telemetry bucket, edge fleet identity; `bootstrap/` holds state bucket + ECR |
| `scripts/` | Bootstrap scripts for Argo CD and edge sites |
| `.github/workflows/` | CI, image/chart publishing, Terraform plan/apply |

## Environments

| Environment | Cluster | Argo CD | Root app |
|---|---|---|---|
| staging | `eks-acumino-staging` | https://argocd.staging.acumino.example | `gitops/clusters/cloud-staging/root.yaml` |
| prod | `eks-acumino-prod` | https://argocd.acumino.example | `gitops/clusters/cloud-prod/root.yaml` |
| edge site | k3s on the site gateway | managed by prod Argo CD | `edge-*` ApplicationSets in prod |

## Bootstrapping a cloud cluster

```bash
./scripts/bootstrap-argocd.sh <staging|prod>
```

Installs Argo CD with Helm, registers the repo and the ECR chart registry, and
applies the root app. From then on Argo CD manages itself and everything under
`gitops/clusters/cloud-<env>/apps/`.

## Releasing

1. Merge to `main`.
2. Tag `vX.Y.Z`. CI builds and pushes the image and chart to ECR.
3. Bump `targetRevision` in `gitops/clusters/cloud-<env>/apps/telemetry-signer.yaml`.
4. Argo CD syncs within a minute.

## Infrastructure changes

- Open a PR touching `infra/terraform/**` and add the `plan` label to get a plan comment.
- After merge, run the `terraform` workflow manually and choose the environment.

## New edge site

```bash
./scripts/bootstrap-edge-site.sh <site-id> <tenant> <gateway-public-address>
```

See the script header for prerequisites.
