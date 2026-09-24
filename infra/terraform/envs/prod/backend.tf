terraform {
  backend "s3" {
    bucket = "acumino-sandbox-tfstate"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
