variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type        = string
  default     = "dev"  # Changed: safer default for dev, override for prod
  description = "Environment name (dev, staging, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be created"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block for security group rules"
  default     = "10.0.0.0/16"
}

variable "github_org" {
  type        = string
  description = "GitHub organization name for OIDC trust"
  default     = "lightinc"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name for OIDC trust"
  default     = "light-platform"
}
