output "cluster_name" {
  value = module.eks.cluster_name
}

output "telemetry_bucket" {
  value = module.telemetry.bucket
}

output "signer_role_arn" {
  value = module.telemetry.signer_role_arn
}

output "lbc_role_arn" {
  value = module.eks.lbc_role_arn
}

output "nat_public_ips" {
  value = module.eks.nat_public_ips
}
