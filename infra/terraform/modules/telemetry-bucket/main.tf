resource "aws_s3_bucket" "telemetry" {
  bucket        = var.bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "telemetry" {
  bucket = aws_s3_bucket.telemetry.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  oidc_host = replace(var.oidc_issuer, "https://", "")
}

data "aws_iam_policy_document" "signer_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringLike"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:*"]
    }
  }
}

resource "aws_iam_role" "signer" {
  name               = var.signer_role_name
  assume_role_policy = data.aws_iam_policy_document.signer_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "signer" {
  statement {
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.telemetry.arn, "${aws_s3_bucket.telemetry.arn}/*"]
  }
}

resource "aws_iam_role_policy" "signer" {
  name   = "s3-telemetry"
  role   = aws_iam_role.signer.id
  policy = data.aws_iam_policy_document.signer.json
}
