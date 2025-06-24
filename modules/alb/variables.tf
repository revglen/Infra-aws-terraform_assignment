variable "name" {
  description = "Name of the ALB and associated resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal or internet-facing"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Enable HTTPS listener"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Health check path for target groups"
  type        = string
  default     = "/health"
}