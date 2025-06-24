output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "database_subnets" {
  description = "List of database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = aws_security_group.app.id
}

output "nginx_security_group_id" {
  description = "NGINX security group ID"
  value       = aws_security_group.nginx.id
}

output "db_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.db.id
}