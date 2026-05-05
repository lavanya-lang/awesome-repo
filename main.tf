# Creates a single production-grade AWS SQS queue named 'grait-queue' in us-east-1 with SQS-managed server-side encryption enabled and standard enterprise tags.
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
}

variable "queue_name" {
  description = "SQS queue name."
  type        = string
  default     = "grait-queue"

  validation {
    condition     = length(var.queue_name) >= 1 && length(var.queue_name) <= 80
    error_message = "SQS queue name must be between 1 and 80 characters."
  }
}

variable "tags" {
  description = "Tags to apply to the SQS queue."
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "grait"
  }
}

provider "aws" {
  {{block_to_replace_cred}}
  region = var.aws_region
}

resource "aws_sqs_queue" "grait" {
  name = var.queue_name

  # Production-grade defaults
  kms_data_key_reuse_period_seconds = 300
  sqs_managed_sse_enabled           = true

  tags = var.tags
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue."
  value       = aws_sqs_queue.grait.arn
}

output "sqs_queue_id" {
  description = "ID (URL) of the SQS queue."
  value       = aws_sqs_queue.grait.id
}

output "sqs_queue_name" {
  description = "Name of the SQS queue."
  value       = aws_sqs_queue.grait.name
}