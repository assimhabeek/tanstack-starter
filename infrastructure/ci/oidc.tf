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
