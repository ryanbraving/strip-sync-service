resource "aws_ssm_parameter" "stripe_api_key" {
  name        = "/stripe-sync-service/stripe_api_key"
  description = "Stripe API Secret Key"
  type        = "SecureString"
  value       = var.stripe_api_key

  tags = {
    service = "stripe-sync-service"
  }
}

resource "aws_ssm_parameter" "stripe_webhook_secret" {
  name        = "/stripe-sync-service/stripe_webhook_secret"
  description = "Stripe Webhook Secret"
  type        = "SecureString"
  value       = var.stripe_webhook_secret

  tags = {
    service = "stripe-sync-service"
  }
}

resource "aws_ssm_parameter" "jwt_secret_key" {
  name        = "/stripe-sync-service/jwt_secret_key"
  description = "Stripe Webhook Secret"
  type        = "SecureString"
  value       = var.jwt_secret_key

  tags = {
    service = "stripe-sync-service"
  }
}