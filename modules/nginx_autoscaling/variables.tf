variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ASG"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 2
}

variable "key_name" {
  description = "SSH key name for instances"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs for instances"
  type        = list(string)
}

variable "frontend_target_group_arn" {
  description = "ARN of frontend ALB target group"
  type        = string
}

variable "app_alb_dns_name" {
  description = "DNS name of the application ALB"
  type        = string
}