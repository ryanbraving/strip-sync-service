resource "aws_db_subnet_group" "stripe_sync" {
  name       = "stripe-sync-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name    = "stripe-sync-db-subnet-group"
    service = "stripe-sync-service"
  }
}

resource "aws_db_instance" "stripe_sync" {
  identifier               = "stripe-sync-db"
  engine                   = "postgres"
  engine_version           = "15.10"
  instance_class           = "db.t4g.micro"
  allocated_storage        = 20
  storage_type             = "gp3"
  username                 = "postgres"
  password                 = "postgres"
  db_name                  = "stripe_db"
  skip_final_snapshot      = true
  publicly_accessible      = true
  delete_automated_backups = true
  vpc_security_group_ids   = [aws_security_group.rds.id]
  db_subnet_group_name     = aws_db_subnet_group.stripe_sync.name
  deletion_protection      = false

  tags = {
    Name    = "stripe-sync-db"
    service = "stripe-sync-service"
  }
}

resource "aws_security_group" "rds" {
  name        = "stripe-sync-rds-sg"
  description = "Allow PostgreSQL access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  ingress {
    description     = "PostgreSQL from Bastion"
    from_port       = 5432
    to_port         = 5432
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
    Name    = "stripe-sync-rds-sg"
    service = "stripe-sync-service"
  }
}
