terraform {
  backend "s3" {
    bucket         = "kamronbek-tfstate-2026"
    key            = "serverless-notes/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}