# infrastructure/cicd_stack_deployment.tf

resource "aws_cloudformation_stack" "cicd_pipelines" {
  name = "${var.project_name}-cicd-stack"

  # THIS IS THE CRITICAL FIX (with the correct argument name):
  # The argument is 'iam_role_arn', not 'role_arn'.
  # This tells CloudFormation to assume the LabRole to create the stack's resources.
  iam_role_arn = var.lab_role_arn

  template_body = file("${path.module}/cicd-stack.yaml")

  parameters = {
    ProjectName          = var.project_name
    LabRoleArn           = var.lab_role_arn
    BackendEcrRepoName   = aws_ecr_repository.backend_api.name
    FrontendS3BucketName = aws_s3_bucket.frontend.id
    FrontendS3BucketArn  = aws_s3_bucket.frontend.arn
    EcsClusterName       = aws_ecs_cluster.main.name
    EcsServiceName       = aws_ecs_service.backend_api.name
    EcsContainerName     = jsondecode(aws_ecs_task_definition.backend_api.container_definitions)[0].name
  }

  # These capabilities are required because the stack creates IAM roles (implicitly via OAI)
  # and other resources with custom names.
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  # Ensure the resources needed for parameters exist before creating the stack
  depends_on = [
    aws_ecs_service.backend_api
  ]
}