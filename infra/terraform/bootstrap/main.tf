# One-off, shared by all environments: remote state bucket and container registries.
# Applied manually with local state.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::476918794945:role/OrganizationAccountAccessRole"
  }
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "acumino-sandbox-tfstate"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_ecr_repository" "this" {
  for_each = toset([
    "telemetry-signer",
    "telemetry-agent",
    "charts/telemetry-signer",
  ])

  name         = each.value
  force_delete = true
}
