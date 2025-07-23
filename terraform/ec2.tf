# Security group for Bastion Host
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH from anywhere and access to RDS/Valkey"
  vpc_id      = aws_vpc.main.id

  # Allow SSH from anywhere (for demo/dev; restrict in prod!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (for RDS/Valkey access)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = "ami-05f991c49d264708f" # Ubuntu 24.04 LTS (X86)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = "ryan-public-key"

  tags = {
    Name = "stripe-sync-bastion"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y postgresql-client redis-tools
  EOF
}