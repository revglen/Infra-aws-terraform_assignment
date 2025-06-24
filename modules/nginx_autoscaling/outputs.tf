output "asg_name" {
  description = "Name of the NGINX ASG"
  value       = aws_autoscaling_group.nginx.name
}

output "security_group_id" {
  description = "Security group ID of NGINX instances"
  value       = var.security_group_ids[0]
}