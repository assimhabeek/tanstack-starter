# --- 1. CodeStar/CodeConnections (GitHub) ---
# NOTE: After 'terraform apply', you MUST go to the AWS Console 
# (Settings > Connections) and click "Update pending connection"
resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

# --- 2. IAM Role for CodeBuild ---
resource "aws_iam_role" "codebuild_pr_role" {
  name = "${var.app_name}-codebuild-pr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_pr_policy" {
  name = "${var.app_name}-codebuild-pr-policy"
  role = aws_iam_role.codebuild_pr_role.id

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
        Resource = "*"
      },
      {
        # THE FIX: CodeBuild needs GetConnectionToken to create the webhook
        Effect = "Allow"
        Action = [
          "codeconnections:UseConnection",
          "codeconnections:GetConnection",
          "codeconnections:GetConnectionToken",
          "codestar-connections:UseConnection",
          "codestar-connections:GetConnection",
          "codestar-connections:GetConnectionToken"
        ]
        Resource = aws_codestarconnections_connection.github.arn
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:RetryBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:BatchGetBuildBatches"
        ]
        # It needs permission to start builds within its own project
        Resource = aws_codebuild_project.codebuild.arn
      }
    ]
  })
}

# --- 3. CodeBuild Project ---
resource "aws_codebuild_project" "codebuild" {
  name          = "${var.app_name}-codebuild"
  description   = "Automated PR checks for TanStack Starter"
  service_role  = aws_iam_role.codebuild_pr_role.arn
  build_timeout = 10

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD" # Uses the service_role for auth
  }

  source {
    type                = "GITHUB"
    location            = "https://github.com/${var.repository_owner}/${var.repository_name}.git"
    git_clone_depth     = 1
    report_build_status = true # This triggers the checkmark in GitHub
    buildspec           = "infrastructure/buildspec.yml"

    auth {
      # This links the project to your GitHub App Connection
      type     = "CODECONNECTIONS"
      resource = aws_codestarconnections_connection.github.arn
    }
  }

  build_batch_config {
    service_role      = aws_iam_role.codebuild_pr_role.arn
    timeout_in_mins   = 60
    combine_artifacts = false
  }
}

# --- 4. Automatic Webhook Management ---
# This resource creates the webhook in your GitHub Repo automatically
resource "aws_codebuild_webhook" "pr_trigger" {
  project_name = aws_codebuild_project.codebuild.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED, PULL_REQUEST_UPDATED, PULL_REQUEST_REOPENED"
    }
    filter {
      type    = "BASE_REF"
      pattern = "^refs/heads/main$" # Only PRs targeting main
    }
  }
}

