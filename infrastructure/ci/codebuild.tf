locals {
  checks = {
    "lint" = {
      buildspec = "lint.yml"
      image     = "aws/codebuild/standard:7.0"
    }
    "test" = {
      buildspec = "test.yml"
      image     = "aws/codebuild/standard:7.0"
    }
    "build" = {
      buildspec = "build.yml"
      image     = "aws/codebuild/standard:7.0"
    }
  }
}

# ── One sub-project per check ─────────────────────────────────────────────────
resource "aws_codebuild_project" "check" {
  for_each = local.checks

  # This name is exactly what appears as the check name on GitHub
  name         = "${var.app_name}-${each.key}"
  service_role = aws_iam_role.codebuild.arn

  source {
    type                = "GITHUB"
    location            = "https://github.com/${var.repository_owner}/${var.repository_name}"
    git_clone_depth     = 1
    buildspec           = each.value.buildspec
    report_build_status = true # ← this is what posts to GitHub Checks

    git_submodules_config {
      fetch_submodules = false
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = each.value.image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.app_name}"
      stream_name = each.key
    }
  }
}

# ── Orchestrator project — runs the batch, references sub-projects ─────────────
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

    git_submodules_config {
      fetch_submodules = false
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

  build_batch_config {
    service_role      = aws_iam_role.codebuild.arn
    combine_artifacts = false
    timeout_in_mins   = 30

    restrictions {
      compute_types_allowed  = ["BUILD_GENERAL1_SMALL"]
      maximum_builds_allowed = 10
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/tanstack-starter-ci"
      stream_name = "orchestrator"
    }
  }

  depends_on = [aws_codebuild_project.check]
}

# ── Webhook on the orchestrator only ─────────────────────────────────────────
resource "aws_codebuild_webhook" "pr_trigger" {
  project_name = aws_codebuild_project.ci.name
  build_type   = "BUILD_BATCH"

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
