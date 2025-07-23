# Main VPC for the application
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "stripe-sync-vpc"
  }
}

# Internet Gateway to allow internet access for public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "stripe-sync-igw"
  }
}

# Public subnet A (us-west-2a)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "stripe-sync-public-subnet-a"
  }
}

# Public subnet B (us-west-2b)
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "stripe-sync-public-subnet-b"
  }
}

# Route table for public subnets (routes 0.0.0.0/0 to the internet gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "stripe-sync-public-rt"
  }
}

# Route for internet access in the public route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate public subnet A with the public route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
  # No tags supported
}

# Associate public subnet B with the public route table
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
  # No tags supported
}

# Private subnet A (us-west-2a)
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false
  tags = {
    Name = "stripe-sync-private-subnet-a"
  }
}

# Private subnet B (us-west-2b)
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = false
  tags = {
    Name = "stripe-sync-private-subnet-b"
  }
}

# Route table for private subnets (no internet route by default)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "stripe-sync-private-rt"
  }
}

# Associate private subnet A with the private route table
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
  # No tags supported
}

# Associate private subnet B with the private route table
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
  # No tags supported
}

# --- NAT Gateway setup for private subnets to access the internet ---

# Allocate an Elastic IP for the NAT Gateway (required for NAT Gateway)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "stripe-sync-nat-eip"
  }
}

# NAT Gateway in public subnet A (enables outbound internet for private subnets)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name = "stripe-sync-nat-gw"
  }
}

# Add route in private route table for outbound internet via NAT Gateway
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
  # This route allows private subnets to reach the internet via the NAT Gateway
}