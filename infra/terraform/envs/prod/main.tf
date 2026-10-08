provider "aws" {
  region = var.region

  default_tags {
    tags = {
      environment = "prod"
      managed-by  = "terraform"
    }
  }
}

module "eks" {
  source = "../../modules/eks-cluster"

  name     = "eks-acumino-prod"
  vpc_cidr = "10.30.0.0/16"
  azs      = ["${var.region}a", "${var.region}b"]

  node_instance_types = ["t4g.small"] # Graviton: ~30% cheaper than t8i.small
  node_min_size       = 3
  node_max_size       = 4
}

module "telemetry" {
  source = "../../modules/telemetry-bucket"

  bucket_name       = "acumino-telemetry-prod"
  signer_role_name  = "telemetry-signer-prod"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer
}

module "edge_fleet" {
  source = "../../modules/edge-fleet"
}
