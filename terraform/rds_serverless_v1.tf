# # Subnet group for Aurora cluster (must span at least 2 AZs)
# resource "aws_db_subnet_group" "stripe_sync" {
#   name       = "stripe-sync-db-subnet-group"
#   subnet_ids =   [aws_subnet.private_a.id, aws_subnet.private_b.id]
#
#   tags = {
#     Name    = "stripe-sync-db-subnet-group"
#     service = "stripe-sync-service"
#   }
# }
#
# # Security group allowing PostgreSQL access from your ECS service and your IP
# resource "aws_security_group" "rds" {
#   name        = "stripe-sync-rds-sg"
#   description = "Allow PostgreSQL access"
#   vpc_id      = aws_vpc.main.id
#
#   ingress {
#     description     = "PostgreSQL from ECS"
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     security_groups = [aws_security_group.ecs_service.id]
#   }
#
#   ingress {
#     description = "PostgreSQL from my IP"
#     from_port   = 5432
#     to_port     = 5432
#     protocol    = "tcp"
#     cidr_blocks = ["208.127.188.155/32"]
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name    = "stripe-sync-rds-sg"
#     service = "stripe-sync-service"
#   }
# }
#
# # Aurora PostgreSQL Serverless v1 cluster
# resource "aws_rds_cluster" "stripe_sync" {
#   cluster_identifier      = "stripe-sync-db-cluster"
#   engine                  = "aurora-postgresql"
#   engine_version          = "11.9" # v1 supports 10.x or 11.x only
#   engine_mode             = "serverless"
#   database_name           = "stripe_db"
#   master_username         = "postgres"
#   master_password         = "postgres"
#   db_subnet_group_name    = aws_db_subnet_group.stripe_sync.name
#   vpc_security_group_ids  = [aws_security_group.rds.id]
#   storage_encrypted       = true
#   skip_final_snapshot     = true
#   deletion_protection     = false
#
#   scaling_configuration {
#     auto_pause               = true
#     min_capacity             = 0     # v1: must be 0, 2, 4, 8, etc.
#     max_capacity             = 2
#     seconds_until_auto_pause = 300   # 5 minutes (minimum allowed)
#   }
#
#   tags = {
#     Name    = "stripe-sync-db-cluster"
#     service = "stripe-sync-service"
#   }
# }
#
# # Note: No aws_rds_cluster_instance block is needed for Aurora Serverless v1!