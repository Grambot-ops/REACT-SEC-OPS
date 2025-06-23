# infrastructure/providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"    }
  }
}

provider "aws" {
  region = var.aws_region
}

# This makes the account ID available for use in other resources.
data "aws_caller_identity" "current" {}