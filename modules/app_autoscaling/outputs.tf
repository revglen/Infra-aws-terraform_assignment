output "alb_dns_name" {
  description = "DNS name of the application ALB"
  value       = aws_lb.app.dns_name
}

output "alb_arn" {
  description = "ARN of the application ALB"
  value       = aws_lb.app.arn
}

output "target_group_arn" {
  description = "ARN of the application target group"
  value       = aws_lb_target_group.app.arn
}

output "security_group_id" {
  description = "Security group ID of application instances"
  value       = var.security_group_ids[0]
}

output "ssh_key_pair" {
  description = "SSH Key Pair"
  value       = aws_key_pair.deployer.key_name
}

output "asg_name" {
  description = "Name of the application autoscaling group"
  value       = aws_autoscaling_group.app.name
}

output "alb_arn_suffix" {
  value = aws_lb.app.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.app.arn_suffix
}