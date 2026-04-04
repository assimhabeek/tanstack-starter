# 1. The ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" # Good for monitoring performance
  }
}

# 2. IAM Execution Role (Allows ECS to pull images from ECR and send logs)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_db_url_access" {
  name = "ECSDBUrlAccess"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [
        aws_secretsmanager_secret.db_url.arn,
        aws_secretsmanager_secret.clerk_secret.arn,
        aws_secretsmanager_secret.sentry_token.arn
      ]
    }]
  })
}

# 3. CloudWatch Log Group (To see your console.logs)
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7
}


resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 0.5 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}"
      image     = "${aws_ecr_repository.app.repository_url}:${var.container_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ],
      environment = [
        { name = "VITE_APP_TITLE", value = var.app_title },
        { name = "VITE_CLERK_PUBLISHABLE_KEY", value = var.clerk_pub_key },
        { name = "VITE_SENTRY_DSN", value = var.sentry_dsn },
        { name = "SENTRY_ORG", value = var.sentry_org },
        { name = "SENTRY_PROJECT", value = var.sentry_project },
        { name = "PORT", value = tostring(var.app_port) },
        {
          name = "DB_CA_CERT",
          # This reads the entire file (all blocks) into the variable
          value = file("${path.module}/certs/us-east-1-bundle.pem")
        },

      ]
      # SENSITIVE: Hidden values pulled at runtime
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.db_url.arn
        },
        {
          name      = "CLERK_SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.clerk_secret.arn
        },
        {
          name      = "SENTRY_AUTH_TOKEN"
          valueFrom = aws_secretsmanager_secret.sentry_token.arn
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name,
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "main" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1 # How many copies of your app to run
  launch_type     = "FARGATE"

  # Allow 2 mins for the app to boot before checking health
  health_check_grace_period_seconds = 120

  # THIS IS THE MAGIC PART:
  # It forces a redeployment even if the Task Definition hasn't changed.
  force_new_deployment = true

  # triggers = {
  # Using a timestamp ensures this value is different every time you run 'apply'
  # redeployment = plantimestamp()
  # }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    assign_public_ip = false # Security: Keep them in the private subnet
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name # Must match the name in container_definitions
    container_port   = var.app_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true # If your new code crashes, it automatically reverts to the old one!
  }

  deployment_controller {
    type = "ECS"
  }

  # Ensure at least 100% of desired tasks are always running
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [aws_lb_listener.http] # Don't start until the listener is ready
}


resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7 # Keeps logs for a week to save on storage costs
}
