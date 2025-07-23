resource "aws_security_group" "valkey_sg" {
  name        = "stripe-sync-valkey-sg"
  description = "Allow Valkey access from app instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Adjust for tighter control if needed
  }

  ingress {
    description     = "Redis from Bastion"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "stripe-sync-valkey-sg"
  }
}

resource "aws_elasticache_subnet_group" "valkey_subnet_group" {
  name       = "stripe-sync-valkey-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "stripe-sync-valkey-subnet-group"
  }
}

resource "aws_elasticache_replication_group" "valkey" {
  replication_group_id       = "stripe-sync-valkey"
  description                = "Stripe Sync Valkey Replication Group"
  engine                     = "valkey"
  engine_version             = "8.0"
  node_type                  = "cache.t3.small"
  num_node_groups            = 1
  replicas_per_node_group    = 0
  parameter_group_name       = "default.valkey8"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.valkey_subnet_group.name
  security_group_ids         = [aws_security_group.valkey_sg.id]
  automatic_failover_enabled = false # Single node

  tags = {
    Name = "stripe-sync-valkey"
  }
}