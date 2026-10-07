output "cluster_name" {
  value = module.eks.cluster_name
}

output "telemetry_bucket" {
  value = module.telemetry.bucket
}

output "signer_role_arn" {
  value = module.telemetry.signer_role_arn
}
