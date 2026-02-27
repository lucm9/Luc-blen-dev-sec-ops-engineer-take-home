variable "name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets for the ALB"
  type        = list(string)
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
  default     = 3000
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS. Leave empty to use HTTP-only listener."
  type        = string
  default     = ""
}

variable "alb_security_group" {
  description = "Security group ID for the ALB (created at root level)"
  type        = string
}


variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
