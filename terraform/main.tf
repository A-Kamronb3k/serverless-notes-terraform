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
}

module "frontend" {
  source  = "./modules/frontend"
  project = "serverless-notes"
  tags = {
    Project = "serverless-notes"
  }
}