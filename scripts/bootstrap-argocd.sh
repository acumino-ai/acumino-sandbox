#!/usr/bin/env bash
# Installs Argo CD on a cloud cluster and hands control over to the root app.
#
# Usage: ./scripts/bootstrap-argocd.sh <staging|prod>
#
# Prereqs: KUBECONFIG pointing at the target EKS cluster, AWS creds for the
# sandbox account, helm, and the repo deploy key in ~/.acumino/.
set -euo pipefail

ENV="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ECR_REGISTRY="476918794945.dkr.ecr.us-east-1.amazonaws.com"

echo ">> Installing Argo CD"
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --version 7.6.12 \
  -f "${ROOT}/gitops/values/argocd/common.yaml" \
  -f "${ROOT}/gitops/values/argocd/${ENV}.yaml" \
  --wait

echo ">> Registering repositories"
kubectl -n argocd create secret generic repo-acumino-sandbox \
  --from-literal=type=git \
  --from-literal=url=git@github.com:acumino-ai/acumino-sandbox.git \
  --from-file=sshPrivateKey="${HOME}/.acumino/repo-deploy-key" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd label secret repo-acumino-sandbox argocd.argoproj.io/secret-type=repository --overwrite

kubectl -n argocd create secret generic repo-ecr-charts \
  --from-literal=type=helm \
  --from-literal=name=ecr-charts \
  --from-literal=enableOCI=true \
  --from-literal=url="${ECR_REGISTRY}/charts" \
  --from-literal=username=AWS \
  --from-literal=password="$(aws ecr get-login-password --region us-east-1)" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd label secret repo-ecr-charts argocd.argoproj.io/secret-type=repository --overwrite

echo ">> Applying root app"
kubectl apply -f "${ROOT}/gitops/clusters/cloud-${ENV}/root.yaml"

echo ">> Initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
