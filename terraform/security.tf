# terraform/security.tf

# 1. Security Group for the Application Load Balancer (ALB)
# Allows public internet traffic on HTTP/HTTPS
resource "aws_security_group" "alb" {
  name        = "react-sec-ops-alb-sg"
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
}

# 2. Security Group for the ECS API Service
# Allows traffic ONLY from the ALB on the API's port (e.g., 8080)
resource "aws_security_group" "ecs_api" {
  name        = "react-sec-ops-ecs-api-sg"
  description = "Allow traffic from ALB to the API"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080 # The port our Node.js app will run on
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Only allows traffic from the ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allows outbound traffic (e.g., to RDS and NAT GW)
  }
}

# 3. Security Group for the RDS Database
# Allows traffic ONLY from the ECS API on the PostgreSQL port (5432)
resource "aws_security_group" "database" {
  name        = "react-sec-ops-db-sg"
  description = "Allow traffic from ECS API to the database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_api.id] # Only allows traffic from our API
  }

  egress { # Not strictly necessary, but good practice
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}