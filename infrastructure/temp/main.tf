terraform {
  cloud {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.14.8"
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_s3_bucket" "name" {
  bucket        = "my-easy-delete-bucket-123456"
  force_destroy = true
}
