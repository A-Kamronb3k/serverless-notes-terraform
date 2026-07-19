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

  # O'zingizning GitHub username va repongiz nomi:
  github_repo = "Kamronbek/serverless-notes"

  # 1-rasmdan olingan S3 state bucket nomi:
  state_bucket = "kamronbek-tfstate-2026"

  # 2-rasmdan olingan ma'lumotlar asosida yig'ilgan Lock Table ARN:
  lock_table_arn = "arn:aws:dynamodb:eu-north-1:911784619656:table/terraform-locks"
}

# Role'larning ARN'larini terminalda aniq ko'rish uchun output'lar:
output "ci_plan_role_arn" {
  value = module.iam.ci_plan_role_arn
}

output "ci_apply_role_arn" {
  value = module.iam.ci_apply_role_arn
}