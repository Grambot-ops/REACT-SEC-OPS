# terraform/codepipeline_frontend.tf

# 1. CodeCommit Repository for the frontend
resource "aws_codecommit_repository" "frontend_react" {
  repository_name = "react-sec-deploy-frontend-react"
  description     = "Source code for the React-Sec-Deploy frontend app"
}

# 2. CodeBuild Project for the frontend
resource "aws_codebuild_project" "frontend_react" {
  name          = "react-sec-deploy-frontend-build"
  description   = "Builds and deploys the React frontend to S3"
  build_timeout = "15"
  service_role  = "arn:aws:iam::596390726685:role/LabRole" # CRITICAL: Use LabRole

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.frontend.id
    }
    environment_variable {
      name  = "CLOUDFRONT_ID"
      value = aws_cloudfront_distribution.main.id
    }
  }

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.frontend_react.clone_url_http
  }
}

# 3. CodePipeline for the frontend
resource "aws_codepipeline" "frontend_react" {
  name     = "react-sec-deploy-frontend-pipeline"
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
        RepositoryName = aws_codecommit_repository.frontend_react.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "BuildAndDeploy"
    action {
      name            = "Build-And-Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.frontend_react.name
      }
    }
  }
}