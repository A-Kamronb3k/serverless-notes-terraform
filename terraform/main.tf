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