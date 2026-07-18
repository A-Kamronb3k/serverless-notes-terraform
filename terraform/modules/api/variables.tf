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

variable "allowed_origins" {
  description = "List of origins allowed by the API Gateway CORS configuration"
  type        = list(string)
}
