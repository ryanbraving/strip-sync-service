variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "aws_account_id" {
  description = "Your AWS account ID"
  type        = string
  default     = "038933440787"
}

variable "stripe_api_key" {
  description = "Stripe API Key"
  type        = string
  sensitive   = true
}

variable "stripe_webhook_secret" {
  description = "Stripe Webhook Secret"
  type        = string
  sensitive   = true
}

variable "jwt_secret_key" {
  description = "SECRET_KEY for signing/validating JWT tokens"
  type        = string
  sensitive   = true
}