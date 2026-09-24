variable "bucket_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer" {
  type = string
}

variable "signer_role_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
