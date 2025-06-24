# Networking Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnets
}

# Database Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
}

# Application Outputs
# output "app_asg_name" {
#   description = "Name of application Auto Scaling Group"
#   value       = module.app_autoscaling.asg_name
# }

# # NGINX Outputs
# output "nginx_alb_dns_name" {
#   description = "DNS name of NGINX ALB"
#   value       = module.alb.dns_name
# }

# output "nginx_asg_name" {
#   description = "Name of NGINX Auto Scaling Group"
#   value       = module.nginx_autoscaling.asg_name
# }

# # Combined Endpoint
# output "web_url" {
#   description = "Public URL for the web application"
#   value       = "https://${module.alb.dns_name}"
# }