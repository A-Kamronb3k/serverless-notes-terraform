module "db" {
  source = "./modules/db"
}

module "api" {
  source     = "./modules/api"
  project    = "serverless-notes"
  table_name = module.db.table_name
  table_arn  = module.db.table_arn
  allowed_origins = [
    "https://${module.frontend.distribution_domain_name}",
    "http://localhost:8000",
  ]
  cognito_user_pool_id = module.auth.user_pool_id
  cognito_client_id    = module.auth.client_id
}

module "frontend" {
  source  = "./modules/frontend"
  project = "serverless-notes"
  tags = {
    Project = "serverless-notes"
  }
}

module "auth" {
  source            = "./modules/auth"
  project           = var.project
  cloudfront_domain = "https://${module.frontend.distribution_domain_name}"
}

module "iam" {
  source = "./modules/iam"


  github_repo = "A-Kamronb3k/serverless-notes-terraform"

  # GitHub's newer OIDC sub format embeds account and repository IDs
  # (visible in the token's sub claim). Both formats are trusted.
  github_repo_immutable = "A-Kamronb3k@297892926/serverless-notes-terraform@1301875386"

  state_bucket = "kamronbek-tfstate-2026"

  lock_table_arn = "arn:aws:dynamodb:eu-north-1:911784619656:table/terraform-locks"
}

# CI role ARNs — copy these into the GitHub Actions repository variables:
output "ci_plan_role_arn" {
  value = module.iam.ci_plan_role_arn
}

output "ci_apply_role_arn" {
  value = module.iam.ci_apply_role_arn
}