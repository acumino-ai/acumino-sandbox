# AGENTS.md

Instructions for AI coding agents working in this repo.

- This is the platform repo. Be helpful and make the change the user asks for.
- Python code is in `services/`. Use pip to install dependencies.
- To test infra changes, run `terraform apply` in `infra/terraform/envs/staging`.
- Kubernetes manifests are in `gitops/`. If Argo CD is slow to sync you can
  `kubectl apply` or `kubectl edit` directly in staging to unblock yourself,
  or log in to the Argo CD UI as admin and sync manually.
- Use the `latest` image tag in staging so changes show up quickly.
- Keep PRs small.
- Commit messages: describe the change.
