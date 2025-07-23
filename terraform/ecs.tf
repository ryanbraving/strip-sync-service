resource "aws_ecs_cluster" "main" {
  name = "stripe-sync-cluster"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for accessing SSM Parameter Store
resource "aws_iam_policy" "ssm_param_access" {
  name        = "ecs-ssm-parameter-access"
  description = "Allow ECS task to access specific SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/stripe-sync-service/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_param_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_param_access.arn
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "stripe-sync-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "stripe-sync",
      image     = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/stripe-sync-service:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 8000,
          hostPort      = 8000,
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "DATABASE_URL",
          value = "postgresql+asyncpg://postgres:postgres@${aws_db_instance.stripe_sync.endpoint}/stripe_db"
        },
        {
          name  = "REDIS_URL",
          value = "redis://${aws_elasticache_replication_group.valkey.primary_endpoint_address}:6379"
        }
      ],
      secrets = [
        {
          name      = "STRIPE_API_KEY",
          valueFrom = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/stripe-sync-service/stripe_api_key"
        },
        {
          name      = "STRIPE_WEBHOOK_SECRET",
          valueFrom = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/stripe-sync-service/stripe_webhook_secret"
        },
        {
          name      = "JWT_SECRET_KEY"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/stripe-sync-service/jwt_secret_key"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/stripe-sync-service"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "stripe-sync-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # Register ECS tasks with the ALB target group
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "stripe-sync" # must match your container definition name
    container_port   = 8000          # must match your app's port
  }

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_iam_role_policy_attachment.ssm_param_attachment,
    aws_lb_listener.app
  ]
}

# Security Group
resource "aws_security_group" "ecs_service" {
  name        = "ecs-service-sg"
  description = "Allow HTTP access to ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "ecs-service-sg"
    service = "stripe-sync-service"
  }
}