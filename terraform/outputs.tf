output "api_endpoint" {
  value       = module.api.api_endpoint
  description = "The HTTP API Gateway endpoint URL"
}

output "frontend_bucket_name" {
  value       = module.frontend.bucket_name
  description = "Name of the S3 bucket hosting the frontend"
}

output "frontend_distribution_id" {
  value       = module.frontend.distribution_id
  description = "CloudFront distribution ID for the frontend"
}

output "frontend_distribution_domain_name" {
  value       = module.frontend.distribution_domain_name
  description = "CloudFront distribution domain name for the frontend"
}