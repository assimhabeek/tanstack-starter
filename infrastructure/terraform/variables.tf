variable "app_name" {
  description = "The name of the application used for tagging and resource naming"
  type        = string
  default     = "tanstack-starter"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The IP range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "The IP range for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "The IP range for the public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "The IP range for the private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "The IP range for the second private subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "app_port" {
  description = "The port the Node.js / TanStack app is listening on"
  type        = number
  default     = 3000
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database administrator name"
  type        = string
  sensitive   = true
}

# --- Clerk Authentication ---
variable "clerk_pub_key" {
  type        = string
  description = "Clerk Publishable Key (Public/Vite)"
}

# --- Sentry Error Tracking ---
variable "sentry_dsn" {
  type        = string
  description = "Public Sentry DSN"
}

variable "sentry_org" {
  type        = string
  description = "Sentry Organization Slug"
}

variable "sentry_project" {
  type        = string
  description = "Sentry Project Slug"
}

variable "sentry_token" {
  type        = string
  description = "Sentry Token"
  sensitive   = true
}

variable "clerk_secret" {
  type        = string
  description = "Clerk Secrete"
  sensitive   = true
}


# --- App General ---
variable "app_title" {
  type        = string
  description = "The title for your VITE_APP_TITLE"
  default     = "My Fullstack App"
}
