# resource "aws_security_group" "redis_sg" {
#   name        = "stripe-sync-redis-sg"
#   description = "Allow Redis access from app instances"
#   vpc_id      = aws_vpc.main.id
#
#   ingress {
#     from_port   = 6379
#     to_port     = 6379
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/16"] # Adjust for tighter control if needed
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
#     Name = "stripe-sync-redis-sg"
#   }
# }
#
# resource "aws_elasticache_subnet_group" "redis_subnet_group" {
#   name       = "stripe-sync-redis-subnet-group"
#   subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
#
#   tags = {
#     Name = "stripe-sync-redis-subnet-group"
#   }
# }
#
# resource "aws_elasticache_cluster" "redis" {
#   cluster_id           = "stripe-sync-redis"
#   engine               = "redis"
#   engine_version       = "7.0"
#   node_type            = "cache.t4g.micro"
#   num_cache_nodes      = 1
#   parameter_group_name = "default.redis7"
#   port                 = 6379
#   subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
#   security_group_ids   = [aws_security_group.redis_sg.id]
#
#   tags = {
#     Name = "stripe-sync-redis"
#   }
# }