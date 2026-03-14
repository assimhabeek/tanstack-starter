# 1. The Subnet Group (Tells RDS which subnets to use)
resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.app_name}-db-subnet-group"
  }
}

# 2. The PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier        = "${var.app_name}-db"
  allocated_storage = 20    # 20GB is usually the Free Tier limit
  storage_type      = "gp3" # General Purpose SSD (latest version)
  engine            = "postgres"
  engine_version    = "15.17"       # Specific version of Postgres
  instance_class    = "db.t3.micro" # Smallest instance (Free Tier eligible)

  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  apply_immediately           = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  skip_final_snapshot = true  # Set to false for production to prevent data loss on delete
  publicly_accessible = false # Keep it hidden from the internet
  multi_az            = false # Set to true for high availability (but it costs more)

  tags = {
    Name = "${var.app_name}-postgres"
  }

  # This tells Terraform: "Don't try to delete the subnets until 
  # the DB is 100% gone and the ENI is detached."
  depends_on = [
    aws_db_subnet_group.main
  ]
}
