output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.this.id
}

output "client_id" {
  description = "Cognito User Pool Client ID for the SPA"
  value       = aws_cognito_user_pool_client.this.id
}

output "cognito_domain" {
  description = "Full Cognito hosted UI domain"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}
