# infrastructure/alb.tf

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target group for the ECS service
resource "aws_lb_target_group" "ecs_api" {
  name        = "${var.project_name}-ecs-api-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# HTTP listener that forwards all traffic by default (we'll add rules later)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default action forwards to the API. We could also set a fixed response.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_api.arn
  }
}

# We will later add a rule for `/api/*` to be more specific.
# For now, this setup works for a single backend.
