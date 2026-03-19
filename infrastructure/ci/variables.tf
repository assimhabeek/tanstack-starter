variable "app_name" {
  description = "The name of the application used for tagging and resource naming"
  type        = string
  default     = "tanstack-starter"
}

variable "repository_owner" {
  description = "The owner of the GitHub repository"
  type        = string
  default     = "assimhabeek"
}

variable "repository_name" {
  description = "The name of the GitHub repository"
  type        = string
  default     = "tanstack-starter"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-3"
}


