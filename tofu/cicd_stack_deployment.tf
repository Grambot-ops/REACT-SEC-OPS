# infrastructure/cicd_stack_deployment.tf

resource "aws_cloudformation_stack" "cicd_pipelines" {
  name          = "${var.project_name}-cicd-stack"
  template_body = file("${path.module}/cicd-stack.yaml")

  parameters = {
    ProjectName         = var.project_name
    LabRoleArn          = var.lab_role_arn
    BackendEcrRepoName  = aws_ecr_repository.backend_api.name
    FrontendS3BucketName = aws_s3_bucket.frontend.id # Pass the bucket name/id
    FrontendS3BucketArn = aws_s3_bucket.frontend.arn  # Pass the bucket ARN
    EcsClusterName      = aws_ecs_cluster.main.name
    EcsServiceName      = aws_ecs_service.backend_api.name
    EcsContainerName    = jsondecode(aws_ecs_task_definition.backend_api.container_definitions)[0].name
  }

  # These capabilities are required because the stack creates IAM roles implicitly via OAI
  # and other resources with names.
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  # Ensure the resources needed for parameters exist before creating the stack
  depends_on = [
    aws_ecs_service.backend_api
  ]
}