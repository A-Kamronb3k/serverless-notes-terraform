output "function_names" {
  description = "Map of function key to Lambda function name"
  value       = { for k, v in aws_lambda_function.function : k => v.function_name }
}

output "invoke_arns" {
  description = "Map of function key to Lambda invoke ARN (for API Gateway integration)"
  value       = { for k, v in aws_lambda_function.function : k => v.invoke_arn }
}
