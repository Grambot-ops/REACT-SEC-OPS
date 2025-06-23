# infrastructure/ecs_backend.tf

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = {
    Name = "${var.project_name}-cluster"
  }
}

resource "aws_ecs_task_definition" "backend_api" {
  family                   = "${var.project_name}-backend-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512 MiB

  # CRITICAL: Use the LabRole for both execution and task roles
  execution_role_arn = var.lab_role_arn
  task_role_arn      = var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-backend-container",
      image     = "${aws_ecr_repository.backend_api.repository_url}:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080
        }
      ],
      # CRITICAL: Securely inject secrets
      secrets = [
        {
          name      = "DB_USER",
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username::"
        },
        {
          name      = "DB_PASSWORD",
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        }
      ],
      environment = [
        {
          name  = "DB_HOST",
          value = aws_rds_cluster.aurora_pg.endpoint
        },
        {
          name  = "DB_NAME",
          value = aws_rds_cluster.aurora_pg.database_name
        },
        {
          name  = "DB_PORT",
          value = tostring(aws_rds_cluster.aurora_pg.port)
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_api.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs_api" {
  name = "/ecs/${var.project_name}-backend-api"
  retention_in_days = 7
}

resource "aws_ecs_service" "backend_api" {
  name            = "${var.project_name}-backend-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend_api.arn
  desired_count   = 1 # Start with 1 task for the lab
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_api.id]
    assign_public_ip = false # Run in private subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_api.arn
    container_name   = "${var.project_name}-backend-container"
    container_port   = 8080
  }

  # Ensure the service waits for the ALB to be ready
  depends_on = [aws_lb_listener.http]
}