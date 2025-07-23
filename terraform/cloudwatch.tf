resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/stripe-sync-service"
  retention_in_days = 1
}