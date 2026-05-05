# Production-grade basic scalable web application stack in eu-central-1: VPC with two public subnets, internet gateway + routes, ALB + listener + target group, launch template (IMDSv2, detailed monitoring) and an Auto Scaling Group named 'hgygfhgtf', with consistent tagging across resources.
# Generated Terraform code for AWS in eu-central-1

terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.25.0"
    }
  }
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group."
  type        = string
  default     = "hgygfhgtf"
}

variable "environment" {
  description = "Environment tag value."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project tag value."
  type        = string
  default     = "hgygfhgtf"
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC hosting the ALB and Auto Scaling group."
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.10.0.0/24", "10.10.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "Provide at least two public subnet CIDRs for HA across AZs."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the web instances."
  type        = string
  default     = "t3.micro"
}

variable "http_port" {
  description = "HTTP port exposed by the ALB and the instances."
  type        = number
  default     = 80
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= 1
    error_message = "desired_capacity must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 4

  validation {
    condition     = var.max_size >= 1
    error_message = "max_size must be at least 1."
  }
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be at least 0."
  }
}

variable "health_check_grace_period" {
  description = "Time (seconds) after instance launch before checking health."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags to apply to all resources. Environment/Project/ManagedBy are always applied."
  type        = map(string)
  default     = {}
}

provider "aws" {
  region = var.region
  {{block_to_replace_cred}}
}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project
    },
    var.tags
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-igw" })
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
  vpc_id                  = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-public-${each.value.az}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-public-rt" })
}

resource "aws_route" "public_default" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_security_group" "alb" {
  description = "ALB security group"
  name        = "${var.project}-${var.environment}-alb-sg"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.http_port
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = var.http_port
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "instance" {
  description = "Instance security group"
  name        = "${var.project}-${var.environment}-instance-sg"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-instance-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "instance_http_from_alb" {
  from_port                    = var.http_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
  security_group_id            = aws_security_group.instance.id
  to_port                      = var.http_port
}

resource "aws_vpc_security_group_egress_rule" "instance_all" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.instance.id
}

resource "aws_lb" "main" {
  internal                   = false
  load_balancer_type         = "application"
  name                       = substr("${var.project}-${var.environment}-alb", 0, 32)
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [for s in aws_subnet.public : s.id]

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-alb" })
}

resource "aws_lb_target_group" "web" {
  name        = substr("${var.project}-${var.environment}-tg", 0, 32)
  port        = var.http_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200-399"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.web.arn
    type             = "forward"
  }
}

resource "aws_launch_template" "web" {
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  name_prefix   = "${var.asg_name}-lt-"

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance.id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -euo pipefail

dnf -y update

dnf -y install nginx

cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>OK</title>
  </head>
  <body>
    <h1>It works</h1>
  </body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-web" })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-web" })
  }

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-launch-template" })
}

resource "aws_autoscaling_group" "web" {
  desired_capacity         = var.desired_capacity
  health_check_grace_period = var.health_check_grace_period
  health_check_type        = "ELB"
  max_size                 = var.max_size
  min_size                 = var.min_size
  name                     = var.asg_name
  target_group_arns        = [aws_lb_target_group.web.arn]
  vpc_zone_identifier      = [for s in aws_subnet.public : s.id]

  launch_template {
    id      = aws_launch_template.web.id
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
    value               = "${var.project}-${var.environment}-asg-instance"
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      propagate_at_launch = true
      value               = tag.value
    }
  }
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the application load balancer."
  value       = aws_lb.main.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.web.name
}

output "launch_template_id" {
  description = "ID of the launch template used by the ASG."
  value       = aws_launch_template.web.id
}

output "target_group_arn" {
  description = "ARN of the target group behind the load balancer."
  value       = aws_lb_target_group.web.arn
}

output "vpc_id" {
  description = "ID of the VPC created for this stack."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [for s in aws_subnet.public : s.id]
}