# AWS CodeBuild Project for Migrations
resource "aws_codebuild_project" "db_migration" {
  name         = "${var.app_name}-migration"
  description  = "Runs database migrations for ${var.app_name}"
  service_role = aws_iam_role.codebuild_migration_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0" # Has Node, Go, Python, etc.
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # Pass DB credentials via Environment Variables (Secrets Manager is safer)
    environment_variable {
      name  = "DATABASE_URL"
      value = aws_secretsmanager_secret.db_url.arn
      type  = "SECRETS_MANAGER"
    }
  }

  vpc_config {
    vpc_id = aws_vpc.main.id
    # Use private subnets that have a route to RDS
    subnets = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    # The security group for CodeBuild itself
    security_group_ids = [aws_security_group.codebuild_migration_sg.id]
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.repository_owner}/${var.repository_name}.git"
    git_clone_depth = 1

    buildspec = <<-EOF
      version: 0.2
      phases:
        install:
          runtime-versions:
            nodejs: 20
          commands:
            - echo "Enabling pnpm via Corepack..."
            - corepack enable
            - corepack prepare pnpm@latest --activate
        pre_build:
          commands:
            - echo "Installing dependencies..."
            - pnpm install --frozen-lockfile
        build:
          commands:
            - echo "Running migrations in the app directory..."
            - cd app && pnpm db:migrate
    EOF
  }
}

resource "aws_iam_role" "codebuild_migration_role" {
  name = "${var.app_name}-codebuild_migration_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_secrets_policy" {
  role = aws_iam_role.codebuild_migration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = [aws_secretsmanager_secret.db_url.arn]
      },
    ]
  })
}


resource "aws_iam_role_policy" "codebuild_cloudwatch" {
  name = "CodeBuildCloudWatchLogsPolicy"
  role = aws_iam_role.codebuild_migration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        # It's best practice to scope this to your project's log group
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/codebuild/${var.app_name}-migration",
          "arn:aws:logs:*:*:log-group:/aws/codebuild/${var.app_name}-migration:*"
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy" "codebuild_vpc_management" {
  name = "CodeBuildVPCManagementPolicy"
  role = aws_iam_role.codebuild_migration_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:CreateNetworkInterfacePermission"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
