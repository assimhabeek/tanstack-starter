resource "aws_codebuild_project" "ci" {
  name         = "${var.app_name}-ci"
  service_role = aws_iam_role.codebuild.arn

  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.repository_owner}/${var.repository_name}"
    git_clone_depth = 1
    buildspec       = "buildspec.yml"

    # No report_build_status here — sub-projects handle their own reporting
    report_build_status = false

    auth {
      type     = "CODECONNECTIONS"
      resource = aws_codestarconnections_connection.github.arn
    }

  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/tanstack-starter-ci"
      stream_name = "orchestrator"
    }
  }

  depends_on = [
    aws_iam_role_policy.codebuild
  ]

}

# ── Webhook on the orchestrator only ─────────────────────────────────────────
resource "aws_codebuild_webhook" "pr_trigger" {
  project_name = aws_codebuild_project.ci.name

  depends_on = [
    aws_codebuild_project.ci,
    aws_codestarconnections_connection.github,
    aws_iam_role_policy.codebuild,
  ]

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED"
    }
  }

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_UPDATED"
    }
  }

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_REOPENED"
    }
  }
}
