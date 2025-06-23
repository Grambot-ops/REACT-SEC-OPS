# infrastructure/ecr.tf

resource "aws_ecr_repository" "backend_api" {
  name                 = "${var.project_name}-backend-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-backend-api-repo"
  }
}