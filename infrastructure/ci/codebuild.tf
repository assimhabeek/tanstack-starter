resource "aws_codebuild_project" "ci" {
  name         = "${var.app_name}-ci"
  service_role = aws_iam_role.codebuild_role.arn

  source {
    type      = "GITHUB"
    location  = "https://github.com/${var.repository_owner}/${var.repository_name}"
    buildspec = "buildspec.yml"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }
}


resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
