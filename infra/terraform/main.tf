# SECURITY FIX: Restrict PostgreSQL access to VPC CIDR only
# Original code allowed 0.0.0.0/0 which exposes DB to the entire internet!
resource "aws_security_group" "postgres_sg" {
  name        = "postgres-sg"
  description = "Postgres security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # Only allow access from within VPC, not the entire internet
    cidr_blocks = [var.vpc_cidr]
    description = "PostgreSQL access from VPC only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "postgres-sg"
    Environment = var.environment
  }
}

# SECURITY FIX: Use OIDC for GitHub Actions instead of long-lived access keys
# Original code created IAM user with static credentials - bad practice!
# OIDC provides short-lived tokens and better security
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })
}

# SECURITY FIX: Apply least-privilege principle
# Original code granted "*" on all resources - full admin access!
# Now only grants specific permissions needed for deployment
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "github-actions-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# SECURITY FIX: Output role ARN for CI configuration, not access keys
# Original code output secret_access_key with sensitive=false!
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM Role ARN for GitHub Actions OIDC"
}
