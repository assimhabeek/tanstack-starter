resource "aws_codepipeline" "pipeline" {
  name          = "${var.app_name}-pipeline"
  role_arn      = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }


  # 🔹 SOURCE (GitHub via CodeStar)
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection" # 🔹 MUST be this
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "${var.repository_owner}/${var.repository_name}"
        BranchName           = "main"
        DetectChanges        = false # required for PR triggers
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  # 🔹 LINT
  stage {
    name = "Lint"

    action {
      name            = "Lint"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.lint.name
      }
    }
  }

  # 🔹 TEST
  stage {
    name = "Test"

    action {
      name            = "Test"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.test.name
      }
    }
  }

  # 🔹 BUILD
  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  trigger {
    provider_type = "CodeStarSourceConnection"

    git_configuration {
      source_action_name = "Source"

      pull_request {
        events = ["OPEN", "UPDATED"]

        branches {
          includes = ["*"] # ✅ ALL target branches
        }
      }
    }
  }

}


