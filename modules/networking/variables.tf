variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "database_subnets" {
  description = "List of database subnet CIDRs"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Should NAT Gateway be created"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for all AZs"
  type        = bool
  default     = false
}