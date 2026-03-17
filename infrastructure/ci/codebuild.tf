resource "aws_codebuild_project" "lint" {
  name         = "${var.app_name}-lint"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type                = "CODEPIPELINE"
    buildspec           = "buildspec.lint.yml"
    report_build_status = true
  }
}

resource "aws_codebuild_project" "test" {
  name         = "${var.app_name}-test"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type                = "CODEPIPELINE"
    buildspec           = "buildspec.test.yml"
    report_build_status = true
  }
}

resource "aws_codebuild_project" "build" {
  name         = "${var.app_name}-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type                = "CODEPIPELINE"
    buildspec           = "buildspec.build.yml"
    report_build_status = true
  }
}
