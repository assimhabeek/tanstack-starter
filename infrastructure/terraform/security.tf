# --- ALB Security Group ---
resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  # Allow HTTP (for redirection)
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${var.app_name}-ecs_tasks"
  vpc_id = aws_vpc.main.id


  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.alb.id] # ONLY allow the ALB to enter
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"] # Required for app boot (Sentry, APIs, etc.)
  }
}

resource "aws_security_group" "codebuild_migration_sg" {
  name   = "${var.app_name}-codebuild_migration_sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Needs internet to run 'pnpm install'
  }
}

# 2. Security Group for the PostgreSQL Database
resource "aws_security_group" "db_sg" {
  name        = "${var.app_name}-db-sg"
  description = "Allow traffic from Web SG only"
  vpc_id      = aws_vpc.main.id

  # Inbound: Allow Postgres (5432) ONLY from our Web SG
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id, aws_security_group.codebuild_migration_sg.id] # The secret sauce
  }

  # Outbound: Usually empty for DBs (more secure)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-db-sg"
  }
}
