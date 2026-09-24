output "bucket" {
  value = aws_s3_bucket.telemetry.bucket
}

output "signer_role_arn" {
  value = aws_iam_role.signer.arn
}
