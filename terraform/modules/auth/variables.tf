variable "project" {
  description = "Project name used as a prefix for Cognito resources"
  type        = string
}

variable "cloudfront_domain" {
  description = "CloudFront URL (format: https://DOMAIN) allowed as an OAuth callback/logout URL"
  type        = string
}
