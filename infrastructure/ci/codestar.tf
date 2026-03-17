# ── CodeStar Connection (GitHub OAuth — no manual tokens) ──────────────────────
# After `terraform apply`, you must visit the AWS Console once to click
# "Update pending connection" and authorize the GitHub OAuth app.
# That's the only manual step — no tokens, no webhooks.
resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}
