# infrastructure/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "A name for the project to prefix resources."
  type        = string
  default     = "reactsecops"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (for app and DB)."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "lab_role_arn" {
  description = "The ARN of the pre-existing LabRole for AWS services."
  type        = string
  default     = "arn:aws:iam::596390726685:role/LabRole" # Your specific LabRole ARN
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "masteruser"
  sensitive   = true
}