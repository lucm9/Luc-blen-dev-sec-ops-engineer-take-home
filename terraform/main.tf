locals {
  azs = ["${var.aws_region}a", "${var.aws_region}b"]
}

#Networking
module "networking" {
  source = "./modules/networking"

  name        = var.name
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  azs         = local.azs
  common_tags = var.common_tags
  kms_key_arn = module.kms.key_arn
}

#Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.name}-${var.environment}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = module.networking.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-alb-sg"
  })
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-${var.environment}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = module.networking.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-ecs-sg"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL - allows inbound from app tier only"
  vpc_id      = module.networking.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-rds-sg"
  })
}

#ALB SG Rules
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from the internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from the internet (redirect to HTTPS)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow outbound to ECS tasks on application port"
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}

#ECS SG Rules
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Allow inbound from ALB on application port"
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Allow outbound to RDS on PostgreSQL port"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow outbound HTTPS for image pulls and AWS APIs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ecs_dns_udp" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow DNS resolution (UDP)"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ecs_dns_tcp" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow DNS resolution (TCP)"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

#RDS SG Rules
resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Allow PostgreSQL from application tier"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

#KMS
module "kms" {
  source = "./modules/kms"

  name        = var.name
  environment = var.environment
  common_tags = var.common_tags
}

#Secrets Manager (DB creds)
module "secrets" {
  source = "./modules/secrets"

  name        = var.name
  environment = var.environment
  db_username = var.db_username
  db_name     = var.db_name
  common_tags = var.common_tags
  kms_key_arn = module.kms.key_arn
}

#Database (RDS PostgreSQL)
module "database" {
  source = "./modules/database"

  name        = var.name
  environment         = var.environment
  isolated_subnet_ids = module.networking.isolated_subnet_ids
  rds_security_group  = aws_security_group.rds.id
  db_name             = var.db_name
  db_username         = var.db_username
  common_tags         = var.common_tags
  kms_key_arn = module.kms.key_arn
}

module "application" {
  source = "./modules/application"

  name       = var.name
  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids
  container_image    = var.container_image
  container_port     = var.container_port
  secret_arn         = module.secrets.secret_arn
  db_host            = module.database.db_endpoint
  ecs_security_group = aws_security_group.ecs.id
  alb_target_group   = module.loadbalancer.target_group_arn
  common_tags        = var.common_tags
  kms_key_arn         = module.kms.key_arn

  depends_on = [module.loadbalancer]
}

#Load Balancer (ALB)
module "loadbalancer" {
  source = "./modules/loadbalancer"

  name       = var.name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  container_port     = var.container_port
  certificate_arn    = var.certificate_arn
  alb_security_group = aws_security_group.alb.id
  common_tags        = var.common_tags
}
