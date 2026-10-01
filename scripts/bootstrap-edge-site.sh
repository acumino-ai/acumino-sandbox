#!/usr/bin/env bash
# Bootstraps a new edge site cluster (k3s on the site gateway box) and registers
# it with the prod Argo CD, which then deploys the edge apps to it.
#
# Usage: ./scripts/bootstrap-edge-site.sh <site-id> <tenant> <gateway-public-address>
#
# Prereqs:
#   - k3s installed on the gateway; its kubeconfig copied to ~/.acumino/sites/<site-id>.yaml
#   - the customer has forwarded TCP 6443 on their router to the gateway and
#     allow-listed our prod NAT IP
#   - argocd CLI logged in to the prod Argo CD (argocd login argocd.acumino.example)
#   - AWS creds for the sandbox account
#   - the fleet OIDC client in ~/.acumino/fleet-oidc-client.env
set -euo pipefail

SITE_ID="$1"
TENANT="$2"
GATEWAY="$3"
SITE_KUBECONFIG="${HOME}/.acumino/sites/${SITE_ID}.yaml"

echo ">> Pointing kubeconfig at the gateway's public address"
# k3s serving cert only has the LAN names, so skip verification for the public address.
kubectl --kubeconfig "${SITE_KUBECONFIG}" config unset clusters.default.certificate-authority-data
kubectl --kubeconfig "${SITE_KUBECONFIG}" config set-cluster default \
  --server "https://${GATEWAY}:6443" --insecure-skip-tls-verify=true
kubectl --kubeconfig "${SITE_KUBECONFIG}" config rename-context default "${SITE_ID}" || true

echo ">> Creating fleet credentials on the site"
k() { kubectl --kubeconfig "${SITE_KUBECONFIG}" "$@"; }
k create namespace edge-system --dry-run=client -o yaml | k apply -f -

k -n edge-system create secret generic edge-fleet-client \
  --from-env-file="${HOME}/.acumino/fleet-oidc-client.env" \
  --dry-run=client -o yaml | k apply -f -

KEY_JSON="$(aws iam create-access-key --user-name edge-fleet)"
k -n edge-system create secret generic edge-aws-logs \
  --from-literal=access_key_id="$(echo "${KEY_JSON}" | jq -r .AccessKey.AccessKeyId)" \
  --from-literal=secret_access_key="$(echo "${KEY_JSON}" | jq -r .AccessKey.SecretAccessKey)" \
  --dry-run=client -o yaml | k apply -f -

echo ">> Registering the site with prod Argo CD"
# argocd cluster add creates an argocd-manager ServiceAccount with cluster-admin
# on the site and stores its token in the prod cluster.
argocd cluster add "${SITE_ID}" \
  --kubeconfig "${SITE_KUBECONFIG}" \
  --name "${SITE_ID}" \
  --label acumino.io/role=edge \
  --annotation acumino.io/site-id="${SITE_ID}" \
  --annotation acumino.io/tenant="${TENANT}" \
  --yes

echo ">> Done. The edge ApplicationSets will pick up ${SITE_ID} within a few minutes."
echo "   Check: argocd app list -l argocd.argoproj.io/application-set-name=edge-telemetry-agent"
