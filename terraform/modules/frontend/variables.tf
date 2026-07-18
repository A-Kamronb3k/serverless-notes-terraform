variable "project" {
  description = "Project name used as a prefix for frontend resources"
  type        = string
}

variable "tags" {
  description = "Tags applied to created resources"
  type        = map(string)
  default     = {}
}
