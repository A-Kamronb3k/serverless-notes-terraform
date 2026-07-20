variable "github_repo" {
  type        = string
  description = "GitHub repository in format owner/repo"
}
variable "state_bucket" {
  type = string
}
variable "lock_table_arn" {
  type = string
}