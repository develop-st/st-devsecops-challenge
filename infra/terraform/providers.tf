terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ADDED: Remote backend for state management
  # Enables team collaboration and state locking
  # Uncomment and configure for production use
  backend "s3" {
    bucket         = "light-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = "light-platform"
    }
  }
}
