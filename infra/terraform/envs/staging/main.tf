provider "aws" {
  region = var.region

  default_tags {
    tags = {
      environment = "staging"
      managed-by  = "terraform"
    }
  }
}

module "eks" {
  source = "../../modules/eks-cluster"

  name     = "eks-acumino-staging"
  vpc_cidr = "10.20.0.0/16"
  azs      = ["${var.region}a", "${var.region}b"]

  node_instance_types = ["t4g.small"] # Graviton: ~30% cheaper than t8i.small
  node_min_size       = 2
  node_max_size       = 3
}

module "telemetry" {
  source = "../../modules/telemetry-bucket"

  bucket_name       = "acumino-telemetry-staging"
  signer_role_name  = "telemetry-signer-staging"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer
}
