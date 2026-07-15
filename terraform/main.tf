module "db" {
  source = "./modules/db"
}

module "api" {
  source     = "./modules/api"
  project    = "serverless-notes"
  table_name = module.db.table_name
  table_arn  = module.db.table_arn
}