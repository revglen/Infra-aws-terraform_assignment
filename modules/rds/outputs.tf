output "endpoint" {
  description = "Connection endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "port" {
  description = "Database port"
  value       = aws_db_instance.postgres.port
}