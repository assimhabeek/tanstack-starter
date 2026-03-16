# --- 1. CodeStar Connection (GitHub) ---
# Note: You must manually complete the handshake in the AWS Console after applying
resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

# --- 2. S3 Bucket for Pipeline Artifacts ---
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket_prefix = "${var.app_name}-pipeline-artifacts-"
  force_destroy = true
}

# --- 3. CodeBuild Project ---
resource "aws_codebuild_project" "tanstack_build" {
  name         = "${var.app_name}-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ECR_URL"
      value = aws_ecr_repository.app.repository_url
    }
  }

  source {
    type                = "CODEPIPELINE"
    buildspec           = "buildspec.yml"
    report_build_status = true
  }
}

# --- 4. The Main Pipeline (V2) ---
resource "aws_codepipeline" "app_pipeline" {
  name           = "${var.app_name}-pipeline"
  role_arn       = aws_iam_role.pipeline_role.arn
  pipeline_type  = "V2"         # Required for Pull Request triggers
  execution_mode = "SUPERSEDED" # Newest commit kills older builds

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  # This trigger captures ALL branches ("**") for PRs
  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      pull_request {
        events = ["OPEN", "UPDATED"]
        branches {
          includes = ["**"]
        }
      }
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "${var.repository_owner}/${var.repository_name}"
        BranchName           = "main" # Default branch
        DetectChanges        = false
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.tanstack_build.name
      }
    }
  }

  # stage {
  #   name = "Deploy"
  #   action {
  #     name            = "Deploy"
  #     category        = "Deploy"
  #     owner           = "AWS"
  #     provider        = "ECS"
  #     version         = "1"
  #     input_artifacts = ["build_output"]

  #     configuration = {
  #       ClusterName = "tanstack-starter-cluster"
  #       ServiceName = "tanstack-starter-service"
  #       FileName    = "imagedefinitions.json"
  #     }
  #   }
  # }
}

# --- 5. Basic IAM Roles ---
resource "aws_iam_role" "pipeline_role" {
  name = "${var.app_name}-pipeline-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codepipeline.amazonaws.com" } }]
  })
}

# Add Managed Policies to Roles (PowerUserAccess for simplicity, refine for Prod!)
resource "aws_iam_role_policy_attachment" "pipeline_attach" {
  role       = aws_iam_role.pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.app_name}-codebuild-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codebuild.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}


resource "aws_iam_role_policy" "codebuild_status_reporting" {
  name = "CodeBuildGitHubStatusReporting"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "codestar-connections:UseConnection"
        Resource = aws_codestarconnections_connection.github.arn
      }
    ]
  })
}
