# 1. Reference the DB instance secret directly
# We remove 'count' so the data source is always part of the plan
data "aws_secretsmanager_secret_version" "rds_password" {
  # Referencing the attribute directly tells Terraform to wait 
  # for the DB to be created before fetching this value.
  secret_id = aws_db_instance.postgres.master_user_secret[0].secret_arn
}

# 2. Parse the JSON from RDS to get the clean password
locals {
  # This decodes the JSON object that RDS automatically creates
  rds_creds = jsondecode(data.aws_secretsmanager_secret_version.rds_password.secret_string)

  # URL encode the password to handle special characters like '#' and '|'
  encoded_pass = urlencode(local.rds_creds.password)

  # Construct the clean connection string using parsed values
  # Note: we use local.rds_creds.password instead of the whole JSON string
  constructed_db_url = "postgresql://${aws_db_instance.postgres.username}:${local.encoded_pass}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}?sslmode=no-verify"
}

# 2. Your existing App Secret (e.g., for the full DATABASE_URL)
resource "aws_secretsmanager_secret" "db_url" {
  name        = "${var.app_name}/database-url"
  description = "Connection string for the TanStack Starter app"

  # This prevents the 'destroy' error if you decide to tear down later
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_url_value" {
  secret_id     = aws_secretsmanager_secret.db_url.id
  secret_string = local.constructed_db_url
}

# 4. Third-Party Shell Secrets (Value to be set manually in Console)
resource "aws_secretsmanager_secret" "clerk_secret" {
  name = "${var.app_name}/clerk-secret-key"
}

resource "aws_secretsmanager_secret" "sentry_token" {
  name = "${var.app_name}/sentry-auth-token"
}


resource "aws_secretsmanager_secret_version" "sentry_token_value" {
  secret_id     = aws_secretsmanager_secret.sentry_token.id
  secret_string = var.sentry_token
}

resource "aws_secretsmanager_secret_version" "clerk_secret_value" {
  secret_id     = aws_secretsmanager_secret.clerk_secret.id
  secret_string = var.clerk_secret
}
