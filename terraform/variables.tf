variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
}

variable "name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "container_image" {
  description = "Container image URI for the Next.js application (GHCR)"
  type        = string
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS listener. Leave empty to use HTTP-only."
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "blen-devsecops"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}
