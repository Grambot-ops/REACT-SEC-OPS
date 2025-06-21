# terraform/ecs.tf

# 1. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "React-Sec-Ops-Cluster"
}

# 2. Application Load Balancer
resource "aws_lb" "main" {
  name               = "react-sec-ops-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "api" {
  name        = "React-Sec-Ops-API-TG"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/health" # Health check endpoint we created in Node.js
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}


# We will add a listener rule later for the API path /api/*

# 3. ECR Repository to store our Docker images
resource "aws_ecr_repository" "api" {
  name                 = "react-sec-ops-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 4. ECS Task Definition - The blueprint for our container
resource "aws_ecs_task_definition" "api" {
  family                   = "react-sec-ops-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512MB

  # This is where we use our pre-existing LabRole so change it.
  # Find your AWS Account ID and replace <ACCOUNT_ID>
  task_role_arn      = "arn:aws:iam::596390726685:role/LabRole" # Role for the container itself (to access Secrets Manager)
  execution_role_arn = "arn:aws:iam::596390726685:role/LabRole" # Role for Fargate agent (to pull image, send logs)

  container_definitions = jsonencode([
    {
      name  = "api-container"
      image = "${aws_ecr_repository.api.repository_url}:latest"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      # This is the magic! Inject secrets as environment variables.
      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.main.address
        },
        {
          name  = "DB_PORT"
          value = tostring(aws_db_instance.main.port)
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.main.db_name
        }
      ]
      
      # Inject ONLY SECRET data using the 'secrets' integration.
      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${aws_secretsmanager_secret.db_creds.arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_creds.arn}:password::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/react-sec-ops-api"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# This log group needs to exist for the container logs
resource "aws_cloudwatch_log_group" "api" {
  name = "/ecs/react-sec-ops-api"
}

# 5. ECS Service - Runs and maintains our Task Definition
resource "aws_ecs_service" "api" {
  name            = "react-sec-ops-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_api.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}