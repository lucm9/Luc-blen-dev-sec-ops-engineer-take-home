terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-task"
  })
}

# Cloudwatch 
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name}-${var.environment}"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn

  tags = var.common_tags
}

# ECS Task Execution Role to pull images and reads secrets
resource "aws_iam_role" "ecs_execution" {
  name = "${var.name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# Task Definition 
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name}-${var.environment}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "${var.name}-app"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${var.secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.secret_arn}:password::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.secret_arn}:dbname::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.secret_arn}:port::"
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = var.db_host
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://localhost:${var.container_port}/api/db-check || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-task"
  })
}

data "aws_region" "current" {}

#ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group
    container_name   = "${var.name}-app"
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-service"
  })
}
