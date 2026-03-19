# ──────────────────────────────────────────────
# OIDC Identity Provider
# ──────────────────────────────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# ──────────────────────────────────────────────
# IAM Role — assumed by GitHub Actions via OIDC
# ──────────────────────────────────────────────
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.repository_owner}/${var.repository_name}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.app_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}


resource "null_resource" "github_secrets" {
  # Re-runs whenever any of these values change
  triggers = {
    role_arn          = aws_iam_role.github_actions.arn
    codebuild_project = aws_codebuild_project.ci.name
    aws_region        = var.aws_region
  }

  provisioner "local-exec" {
    command = <<-EOT
      gh secret set AWS_ROLE_ARN --body "${aws_iam_role.github_actions.arn}"
      gh secret set AWS_REGION --body "${var.aws_region}"
      gh secret set CODEBUILD_PROJECT_NAME --body "${aws_codebuild_project.ci.name}"
      echo "GitHub secrets updated successfully"
    EOT
  }
}

# ──────────────────────────────────────────────
# IAM Policy — CodeBuild permissions
# ──────────────────────────────────────────────
data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds",
      "codebuild:StopBuild", # Added: Helpful if you need to cancel a hung job
    ]
    resources = [aws_codebuild_project.ci.arn]
  }

  # Often required if your CodeBuild project sits inside a VPC
  # or if the runner needs to check the project configuration.
  statement {
    effect    = "Allow"
    actions   = ["codebuild:ListBuildsForProject"]
    resources = [aws_codebuild_project.ci.arn]
  }
}

resource "aws_iam_policy" "github_actions" {
  name = "${var.app_name}-github-actions-policy"
  # FIX: Added .json to convert the data object to a string
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
