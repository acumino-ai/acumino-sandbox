terraform {
  backend "s3" {
    bucket = "acumino-sandbox-tfstate"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }
}
