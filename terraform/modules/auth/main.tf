terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

data "aws_region" "current" {}

resource "aws_cognito_user_pool" "this" {
  name = "${var.project}-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.project}-spa"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = [
    "http://localhost:8000",
    var.cloudfront_domain,
  ]

  logout_urls = [
    "http://localhost:8000",
    var.cloudfront_domain,
  ]
}

resource "random_string" "domain_prefix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${var.project}-${random_string.domain_prefix.result}"
  user_pool_id = aws_cognito_user_pool.this.id
}
