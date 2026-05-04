# Production-grade AWS Auto Scaling Group for payments-api using a launch template with custom AMI and user_data, attached to an ALB target group, with VPC/public subnets/IGW routing and an HTTP (80) security group.
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

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "payments"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "environment" {
  description = "Environment name used for resource naming and tagging"
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "environment must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "ami_id" {
  description = "Custom AMI ID for the payments-api instances"
  type        = string

  validation {
    condition     = can(regex("^ami-[a-z0-9]{17}$", var.ami_id))
    error_message = "ami_id must look like ami-xxxxxxxxxxxxxxxxx (17 hex characters)"
  }
}

variable "instance_type" {
  description = "EC2 instance type for the payments-api instances"
  type        = string
  default     = "t3.micro"
}

variable "user_data" {
  description = "User data script used to bootstrap the payments-api application"
  type        = string
  default     = ""
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "health_check_grace_period" {
  description = "Health check grace period for the Auto Scaling Group (seconds)"
  type        = number
  default     = 120
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

provider "aws" {
  region = var.region

  {{block_to_replace_cred}}
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.project}-${var.environment}-payments-api"

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project
    },
    var.tags
  )
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "main" {
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-igw" })
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-rt-public" })
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_default" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_subnet" "public" {
  for_each = {
    for idx, cidr in var.public_subnet_cidrs : tostring(idx) => {
      az   = data.aws_availability_zones.available.names[idx]
      cidr = cidr
    }
  }

  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  tags                    = merge(local.common_tags, { Name = "${local.name_prefix}-subnet-public-${each.value.az}" })
  vpc_id                  = aws_vpc.main.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_security_group" "payments_api" {
  description = "Security group for payments-api (HTTP inbound)"
  name_prefix = "${local.name_prefix}-sg-"
  tags        = merge(local.common_tags, { Name = "${local.name_prefix}-sg" })
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.payments_api.id
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "all" {
  ip_protocol       = "-1"
  security_group_id = aws_security_group.payments_api.id
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb_target_group" "payments_api" {
  name        = substr(replace("${local.name_prefix}-tg", "_", "-"), 0, 32)
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200-399"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-tg" })
}

resource "aws_launch_template" "payments_api" {
  image_id      = var.ami_id
  instance_type = var.instance_type
  name_prefix   = "${local.name_prefix}-lt-"
  user_data     = base64encode(var.user_data)

  vpc_security_group_ids = [aws_security_group.payments_api.id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, { Name = "${local.name_prefix}-ec2" })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(local.common_tags, { Name = "${local.name_prefix}-ebs" })
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-lt" })
}

resource "aws_autoscaling_group" "payments_api" {
  desired_capacity          = var.asg_desired_capacity
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = "ELB"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  name                      = "${local.name_prefix}-asg"

  target_group_arns = [aws_lb_target_group.payments_api.arn]

  vpc_zone_identifier = [for s in aws_subnet.public : s.id]

  launch_template {
    id      = aws_launch_template.payments_api.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    propagate_at_launch = true
    value               = var.environment
  }

  tag {
    key                 = "ManagedBy"
    propagate_at_launch = true
    value               = "terraform"
  }

  tag {
    key                 = "Project"
    propagate_at_launch = true
    value               = var.project
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${local.name_prefix}-ec2"
  }
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.payments_api.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.payments_api.id
}

output "security_group_id" {
  description = "Security group ID for payments-api"
  value       = aws_security_group.payments_api.id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.payments_api.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ASG"
  value       = [for s in aws_subnet.public : s.id]
}