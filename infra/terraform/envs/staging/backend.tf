terraform {
  backend "s3" {
    bucket = "acumino-sandbox-tfstate"
    key    = "staging/terraform.tfstate"
    region = "us-east-1"
  }
}
