provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::476918794945:role/OrganizationAccountAccessRole"
  }

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

  node_instance_types = ["t8i.small"]
  node_min_size       = 1
  node_max_size       = 2
}

module "telemetry" {
  source = "../../modules/telemetry-bucket"

  bucket_name       = "acumino-telemetry-staging"
  signer_role_name  = "telemetry-signer-staging"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer
}
