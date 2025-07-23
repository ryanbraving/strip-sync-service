# output "vpc_id" {
#   value = aws_vpc.main.id
# }

# output "public_subnet_ids" {
#   value = [
#     aws_subnet.public_a.id,
#     aws_subnet.public_b.id,
#   ]
# }

output "ALB" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "POSTGRES" {
  description = "PostgreSQL RDS endpoint"
  value       = aws_db_instance.stripe_sync.address
}

# output "ecs_service_security_group_id" {
#   description = "The security group ID for the ECS service"
#   value       = aws_security_group.ecs_service.id
# }

output "PSQL" {
  description = "Command to connect to the Postgres database"
  value       = "psql 'host=${aws_db_instance.stripe_sync.address} port=5432 dbname=stripe_db user=postgres password=postgres'"
}

# output "redis_endpoint" {
#   value = aws_elasticache_cluster.redis.cache_nodes[0].address
# }

output "REDIS" {
  value = aws_elasticache_replication_group.valkey.primary_endpoint_address
}

output "BASTION" {
  description = "EC2 bastion host ip address"
  value       = aws_instance.bastion.public_ip
}