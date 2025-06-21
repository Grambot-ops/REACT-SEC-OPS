# terraform/providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    random = {
      source  = "hashicorp/random"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" # Or your preferred Learner Lab region
}