# # Subnet group for Aurora cluster (must span at least 2 AZs)
# resource "aws_db_subnet_group" "stripe_sync" {
#   name       = "stripe-sync-db-subnet-group"
#   subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
#
#   tags = {
#     Name    = "stripe-sync-db-subnet-group"
#     service = "stripe-sync-service"
#   }
# }
#
# # Security group allowing PostgreSQL access from your ECS service
# resource "aws_security_group" "rds" {
#   name        = "stripe-sync-rds-sg"
#   description = "Allow PostgreSQL access"
#   vpc_id      = aws_vpc.main.id
#
#   ingress {
#     description     = "PostgreSQL"
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     security_groups = [aws_security_group.ecs_service.id]
#   }
#
#   ingress {
#   description = "PostgreSQL from my IP"
#   from_port   = 5432
#   to_port     = 5432
#   protocol    = "tcp"
#   cidr_blocks = ["208.127.188.155/32"]
# }
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
# # Aurora PostgreSQL Serverless v2 cluster
# resource "aws_rds_cluster" "stripe_sync" {
#   cluster_identifier      = "stripe-sync-db-cluster"
#   engine                  = "aurora-postgresql"
#   engine_version          = "15.4" # Use a supported Aurora PG version
#   database_name           = "stripe_db"
#   master_username         = "postgres"
#   master_password         = "postgres"
#   db_subnet_group_name    = aws_db_subnet_group.stripe_sync.name
#   vpc_security_group_ids  = [aws_security_group.rds.id]
#   storage_encrypted       = true
#   skip_final_snapshot     = true
#   deletion_protection     = false
#
#   # Serverless v2 scaling config (min 0.5 ACU, cannot be 0)
#   serverlessv2_scaling_configuration {
#     min_capacity = 0.5  # Minimum allowed by AWS
#     max_capacity = 2    # Adjust as needed for your workload
#   }
#
#   tags = {
#     Name    = "stripe-sync-db-cluster"
#     service = "stripe-sync-service"
#   }
# }
#
# # At least one cluster instance is required for Aurora Serverless v2
# resource "aws_rds_cluster_instance" "stripe_sync" {
#   identifier              = "stripe-sync-db-instance-1"
#   cluster_identifier      = aws_rds_cluster.stripe_sync.id
#   instance_class          = "db.serverless"
#   engine                  = aws_rds_cluster.stripe_sync.engine
#   engine_version          = aws_rds_cluster.stripe_sync.engine_version
#   publicly_accessible     = true
#   db_subnet_group_name    = aws_db_subnet_group.stripe_sync.name
#
#   tags = {
#     Name    = "stripe-sync-db-instance-1"
#     service = "stripe-sync-service"
#   }
# }