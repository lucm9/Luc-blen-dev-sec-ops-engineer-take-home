aws_region = "us-east-1"

name        = "blen-devsecops"
environment = "production"

vpc_cidr = "10.0.0.0/16"

container_image = "ghcr.io/example/blen-devsecops:latest"
container_port  = 3000

db_name     = "blenapp"
db_username = "blendbadmin"

certificate_arn = ""

common_tags = {
  Project     = "blen-devsecops"
  ManagedBy   = "terraform"
  Environment = "production"
}