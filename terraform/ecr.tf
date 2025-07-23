resource "aws_ecr_repository" "stripe_sync" {
  name                 = "stripe-sync-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "stripe-sync-ecr"
  }
}

# Create a lifecycle policy to keep only the most recent image
resource "aws_ecr_lifecycle_policy" "keep_latest" {
  repository = aws_ecr_repository.stripe_sync.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the most recent image"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}