variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "ecommerce"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  #default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  default = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  #default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  #default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  #default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  default = ["10.0.201.0/24", "10.0.202.0/24"]
}

# Database Variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "ecommercedb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "postgres"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

# Autoscaling Variables
variable "desired_capacity" {
  description = "Initial number of EC2 instances in the ASG"
  type        = number
  default     = 2 # Default to match min_size (optional)
}

variable "app_instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t2.micro"
}

variable "app_min_size" {
  description = "Minimum number of application instances"
  type        = number
  default     = 1
}

variable "app_max_size" {
  description = "Maximum number of application instances"
  type        = number
  default     = 2
}

variable "nginx_instance_type" {
  description = "EC2 instance type for NGINX servers"
  type        = string
  default     = "t2.micro"
}

variable "nginx_min_size" {
  description = "Minimum number of NGINX instances"
  type        = number
  default     = 1
}

variable "nginx_max_size" {
  description = "Maximum number of NGINX instances"
  type        = number
  default     = 2
}

variable "ssh_key_name" {
  description = "Name of existing EC2 key pair"
  type        = string
  default     = "ecomm-key"
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = ""
}