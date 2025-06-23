# infrastructure/security_groups.tf

# Security Group for the Application Load Balancer (ALB)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/S traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Security Group for the ECS Fargate Service (Backend API)
resource "aws_security_group" "ecs_api" {
  name        = "${var.project_name}-ecs-api-sg"
  description = "Allow traffic from ALB to ECS API"
  vpc_id      = aws_vpc.main.id

  # Allow traffic from the ALB on port 8080 (our Node.js app port)
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allows outbound access for pulling images, etc.
  }

  tags = {
    Name = "${var.project_name}-ecs-api-sg"
  }
}

# Security Group for the Aurora Database
resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Allow traffic from ECS API to Database"
  vpc_id      = aws_vpc.main.id

  # Allow traffic from the ECS API security group on the PostgreSQL port
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_api.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}