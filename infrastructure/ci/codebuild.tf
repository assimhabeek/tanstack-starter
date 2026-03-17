resource "aws_codebuild_project" "ci" {
  name          = "${var.app_name}-ci"
  description   = "CI pipeline for ${var.app_name}"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 30

  # ── Source: GitHub via CodeStar (no manual token) ──────────────────────────
  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.repository_owner}/${var.repository_name}"
    git_clone_depth = 1
    buildspec       = "buildspec.yml"

    auth {
      type     = "CODECONNECTIONS"
      resource = aws_codestarconnections_connection.github.arn
    }
    # Report each sub-build as an individual GitHub Check
    # CODEBUILD_BUILD_ID → unique check name per sub-build
    report_build_status = true

    git_submodules_config {
      fetch_submodules = false
    }

  }


  # ── Artifacts ──────────────────────────────────────────────────────────────
  artifacts {
    type = "NO_ARTIFACTS"
  }

  # ── Environment ────────────────────────────────────────────────────────────
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  # ── Batch build configuration ──────────────────────────────────────────────
  build_batch_config {
    service_role      = aws_iam_role.codebuild.arn
    combine_artifacts = false

    restrictions {
      compute_types_allowed  = ["BUILD_GENERAL1_SMALL"]
      maximum_builds_allowed = 10
    }

    timeout_in_mins = 30
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/my-app-ci"
      stream_name = "build-log"
    }
  }

  lifecycle {
    precondition {
      condition     = aws_codestarconnections_connection.github.connection_status == "AVAILABLE"
      error_message = "The CodeStar Connection is not yet authorized. Go to AWS Console → Developer Tools → Connections → update-pending-connection, complete the GitHub OAuth flow, then re-run terraform apply."
    }
  }
}

resource "null_resource" "batch_report_mode" {
  triggers = {
    project_name = aws_codebuild_project.ci.name
    role_arn     = aws_iam_role.codebuild.arn
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws codebuild update-project \
        --name ${aws_codebuild_project.ci.name} \
        --build-batch-config '{"serviceRole":"${aws_iam_role.codebuild.arn}","batchReportMode":"REPORT_INDIVIDUAL_BUILDS","timeoutInMins":30,"restrictions":{"maximumBuildsAllowed":10,"computeTypesAllowed":["BUILD_GENERAL1_SMALL"]}}' \
        --region ${var.aws_region}
    EOT
  }

  depends_on = [aws_codebuild_project.ci]
}

# ── Webhook: auto-created by Terraform, triggers on PR events ─────────────────
# No manual webhook setup in GitHub needed.
resource "aws_codebuild_webhook" "pr_trigger" {
  project_name = aws_codebuild_project.ci.name
  build_type   = "BUILD_BATCH" # triggers a batch build, not a single build

  # Force webhook to wait until project is fully created
  depends_on = [
    aws_codebuild_project.ci,
    aws_codestarconnections_connection.github,
    aws_iam_role_policy.codebuild, # IAM must be attached before webhook calls GitHub
  ]

  filter_group {
    # Trigger on PR open
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED"
    }
  }

  filter_group {
    # Trigger on PR update (new commits pushed)
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_UPDATED"
    }
  }

  filter_group {
    # Trigger on PR re-open
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_REOPENED"
    }
  }
}
