module "db" {
  source = "./modules/db"
}

module "api" {
  source     = "./modules/api"
  project    = "serverless-notes"
  table_name = module.db.table_name
  table_arn  = module.db.table_arn
}

module "frontend" {
  source  = "./modules/frontend"
  project = "serverless-notes"
  tags = {
    Project = "serverless-notes"
  }
}