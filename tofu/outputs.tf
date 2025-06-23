# infrastructure/outputs.tf

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "ecs_api_sg_id" {
  value = aws_security_group.ecs_api.id
}

output "db_credentials_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "db_cluster_endpoint" {
  value = aws_rds_cluster.aurora_pg.endpoint
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

# --- Outputs from CloudFormation Stack ---

output "cloudfront_domain_name" {
  description = "The domain name for the frontend application (from CloudFormation)"
  value       = aws_cloudformation_stack.cicd_pipelines.outputs["CloudFrontDomainName"]
}

output "backend_repo_clone_url" {
  description = "The HTTPS clone URL for the backend repository (from CloudFormation)"
  value       = aws_cloudformation_stack.cicd_pipelines.outputs["BackendRepoCloneUrlHttp"]
}

output "frontend_repo_clone_url" {
  description = "The HTTPS clone URL for the frontend repository (from CloudFormation)"
  value       = aws_cloudformation_stack.cicd_pipelines.outputs["FrontendRepoCloneUrlHttp"]
}