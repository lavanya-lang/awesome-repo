# Applied a safe retry by restructuring the configuration into standard Terraform files without changing behavior.
            # Modified Terraform Code for AWS in us-east-1

            terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.25.0"
    }
  }
}

            variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name."
  type        = string
  default     = "testsfygrait1234"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

            provider "aws" {
  {{block_to_replace_cred}}
  region = var.aws_region
}

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
}

            output "s3_bucket_id" {
  description = "The name (ID) of the S3 bucket."
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.main.arn
}