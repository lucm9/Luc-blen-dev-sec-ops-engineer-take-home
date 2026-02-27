terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

#DB Subnet Group (isolated subnets only)
resource "aws_db_subnet_group" "main" {
  name        = "${var.name}-${var.environment}-db-subnet-group"
  description = "Isolated subnet group for RDS"
  subnet_ids  = var.isolated_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-db-subnet-group"
  })
}

#RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.name}-${var.environment}-postgres"
  engine         = "postgres"
  engine_version = "17.4"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  # Password is managed via AWS Secrets Manager
  manage_master_user_password = true

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group]
  publicly_accessible    = false

  backup_retention_period   = 7
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-${var.environment}-final-snapshot"
  deletion_protection       = true
  copy_tags_to_snapshot     = true

  performance_insights_enabled        = true
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.rds_monitoring.arn
  iam_database_authentication_enabled = true
  performance_insights_kms_key_id     = var.kms_key_arn

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  auto_minor_version_upgrade = true

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-postgres"
  })
}

#Enhanced Monitoring IAM Role
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
