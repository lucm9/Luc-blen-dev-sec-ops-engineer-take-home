variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "blen-devsecops"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_image" {
  description = "Container image URI for the Next.js application (GHCR)"
  type        = string
  default     = "ghcr.io/example/blen-devsecops:latest"
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
  default     = 3000
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "blenapp"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "blendbadmin"
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS listener. Leave empty to use HTTP-only."
  type        = string
  default     = "arn:aws:acm:us-east-1:533267047415:certificate/29ceb78a-3a8f-4c10-ba2d-9418ac3c949f"
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
