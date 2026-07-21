variable "github_repo" {
  type        = string
  description = "GitHub repository in format owner/repo"
}
variable "github_repo_immutable" {
  type        = string
  description = "GitHub repository in immutable OIDC sub format: owner@owner_id/repo@repo_id"
}
variable "state_bucket" {
  type = string
}
variable "lock_table_arn" {
  type = string
}