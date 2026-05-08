# Basic AWS Terraform scaffold for us-east-1 with enterprise-friendly tagging via provider default_tags; includes no AWS resources (only provider configuration) to keep the plan minimal and ready for a hybrid GitOps workflow.
# Generated Terraform code for AWS in us-east-1

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
  validation {
    condition     = length(var.aws_region) > 0
    error_message = "aws_region must be a non-empty string."
  }
}

variable "project" {
  description = "Project name used for resource naming and tagging."
  type        = string
  default     = "basic"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.project))
    error_message = "project may only contain letters, numbers, underscores, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment used for tagging (e.g., prod, staging)."
  type        = string
  default     = "prod"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.environment))
    error_message = "environment may only contain letters, numbers, underscores, and hyphens."
  }
}

variable "tags" {
  description = "Additional tags to apply to all taggable resources."
  type        = map(string)
  default     = {}
}

provider "aws" {
  {{block_to_replace_cred}}

  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Environment = var.environment
        ManagedBy   = "terraform"
        Project     = var.project
      },
      var.tags
    )
  }
}

output "aws_region" {
  description = "AWS region configured for this Terraform deployment."
  value       = var.aws_region
}

output "tags" {
  description = "Effective default tags configured on the AWS provider."
  value       = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project
    },
    var.tags
  )
}