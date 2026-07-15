variable "project" {
  description = "Project name used as a prefix for Lambda and IAM resources"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name passed to Lambda as TABLE_NAME"
  type        = string
}

variable "table_arn" {
  description = "DynamoDB table ARN for least-privilege IAM policies"
  type        = string
}
