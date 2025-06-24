output "alb_dns_name" {
  description = "DNS name of the frontend ALB"
  value       = aws_lb.frontend.dns_name
}

output "alb_arn" {
  description = "ARN of the frontend ALB"
  value       = aws_lb.frontend.arn
}

output "target_group_arn" {
  description = "ARN of the target group for NGINX instances"
  value       = aws_lb_target_group.nginx.arn
}

output "security_group_id" {
  description = "Security group ID of the frontend ALB"
  value       = aws_security_group.alb.id
}