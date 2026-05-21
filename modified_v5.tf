# Creates a production-grade AWS VPC in us-east-1 with 3 public and 3 private subnets across 3 AZs, an Internet Gateway, per-AZ NAT Gateways, and public/private route tables with associations. Outputs VPC ID and subnet IDs.
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
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
  default     = "network"

  validation {
    condition     = length(var.project) > 0
    error_message = "project must not be empty."
  }
}

variable "environment" {
  description = "Environment name used for naming and tagging."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, stage, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Exactly 3 Availability Zones to spread subnets across."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "availability_zones must contain exactly 3 AZs."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

provider "aws" {
  {{block_to_replace_cred}}

  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(
    [for az in var.availability_zones : az if contains(data.aws_availability_zones.available.names, az)],
    0,
    3
  )

  name_prefix = "${var.project}-${var.environment}"

  # Best-practice subnetting within a /16:
  # - 6 subnets total (3 public + 3 private)
  # - Each subnet is a /20 (large enough for growth)
  #   cidrsubnet(newbits=4) -> 16 subnets of size /20
  public_subnet_cidrs  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i in range(3) : cidrsubnet(var.vpc_cidr, 4, i + 3)]

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

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  for_each = {
    for idx, az in local.azs : az => {
      az   = az
      cidr = local.public_subnet_cidrs[idx]
      idx  = idx
    }
  }

  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-${each.value.az}"
      Tier = "public"
    }
  )
}

resource "aws_subnet" "private" {
  for_each = {
    for idx, az in local.azs : az => {
      az   = az
      cidr = local.private_subnet_cidrs[idx]
      idx  = idx
    }
  }

  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-${each.value.az}"
      Tier = "private"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rtb-public"
      Tier = "public"
    }
  )
}

resource "aws_route" "public_default" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_eip" "nat" {
  for_each = aws_subnet.public

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eip-nat-${each.key}"
    }
  )
}

# Production-grade: one NAT Gateway per AZ (high availability, avoids cross-AZ data charges)
resource "aws_nat_gateway" "main" {
  for_each = aws_subnet.public

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-${each.key}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rtb-private-${each.key}"
      Tier = "private"
    }
  )
}

resource "aws_route" "private_default" {
  for_each = aws_route_table.private

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[each.key].id
  route_table_id         = each.value.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  route_table_id = aws_route_table.private[each.key].id
  subnet_id      = each.value.id
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the 3 public subnets (one per AZ)."
  value       = [for az in local.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "IDs of the 3 private subnets (one per AZ)."
  value       = [for az in local.azs : aws_subnet.private[az].id]
}