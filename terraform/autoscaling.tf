# ----------------------------------------
# IAM Role for Application Auto Scaling
# ----------------------------------------
resource "aws_iam_role" "ecs_autoscale_role" {
  name = "ecsAutoscaleRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    service = "stripe-sync-service"
  }
}

# ----------------------------------------
# Attach AWS Managed Policy for Auto Scaling
# ----------------------------------------
resource "aws_iam_role_policy_attachment" "ecs_autoscale_policy" {
  role       = aws_iam_role.ecs_autoscale_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

# ----------------------------------------
# Register ECS Service with Application Auto Scaling
# ----------------------------------------
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = aws_iam_role.ecs_autoscale_role.arn
}

# ----------------------------------------
# Define CPU-based Scaling Policy
# ----------------------------------------
resource "aws_appautoscaling_policy" "cpu_scale_policy" {
  name               = "cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}