# terraform/codepipeline_backend.tf

# 1. CodeCommit Repository for the backend
resource "aws_codecommit_repository" "backend_api" {
  repository_name = "react-sec-ops-backend-api"
  description     = "Source code for the React-Sec-ops backend API"
}

# 2. CodeBuild Project for the backend
resource "aws_codebuild_project" "backend_api" {
  name          = "react-sec-ops-backend-build"
  description   = "Builds, scans, and pushes the backend API Docker image"
  build_timeout = "15"
  service_role  = "arn:aws:iam::596390726685:role/LabRole" # CRITICAL: Use LabRole

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true # Required for building Docker images
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "596390726685" # Replace with your Account ID
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-east-1"
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.api.name
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source {
    type      = "CODECOMMIT"
    location  = aws_codecommit_repository.backend_api.clone_url_http
  }
}

# 3. CodePipeline for the backend
resource "aws_codepipeline" "backend_api" {
  name     = "react-sec-ops-backend-pipeline"
  role_arn = "arn:aws:iam::596390726685:role/LabRole" # CRITICAL: Use LabRole

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName = aws_codecommit_repository.backend_api.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.backend_api.name
      }
    }
  }

  # Deploy stage is manual for now. The pipeline just builds the image.
  # ECS service will automatically pull the new 'latest' image if we force a new deployment.
  # This can be automated further with a Deploy stage.
}

# We need an S3 bucket for pipeline artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "react-sec-ops-pipeline-artifacts-reactsecops1" # Must be globally unique!
}