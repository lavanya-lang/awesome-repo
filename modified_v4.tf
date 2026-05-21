# Creates a production-grade public-subnet EC2 deployment in us-east-1: VPC, public subnet with auto-assign public IPs, Internet Gateway, public route table with 0.0.0.0/0 route, a security group allowing SSH from 0.0.0.0/0 (demo), and an EC2 t2.micro using the latest Amazon Linux 2 AMI. All resources are tagged with ManagedBy=Terraform and the instance public IP is output.
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

variable "associate_public_ip_address" {
  description = "Whether to associate a public IPv4 address to the instance network interface. For a public subnet, this should be true."
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "managed_by_tag" {
  description = "Value for the ManagedBy tag applied to all resources"
  type        = string
  default     = "Terraform"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH to the instance (demo setting: 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
  validation {
    condition     = can(cidrnetmask(var.ssh_ingress_cidr))
    error_message = "ssh_ingress_cidr must be a valid IPv4 CIDR (e.g., 0.0.0.0/0)."
  }
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be a valid IPv4 CIDR (e.g., 10.0.1.0/24)."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR (e.g., 10.0.0.0/16)."
  }
}

provider "aws" {
  {{block_to_replace_cred}}

  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    ManagedBy = var.managed_by_tag
    Name      = "public-ec2-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  tags = {
    ManagedBy = var.managed_by_tag
    Name      = "public-ec2-igw"
  }

  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id

  tags = {
    ManagedBy = var.managed_by_tag
    Name      = "public-ec2-subnet-public"
  }
}

resource "aws_route_table" "public" {
  tags = {
    ManagedBy = var.managed_by_tag
    Name      = "public-ec2-rt-public"
  }

  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_default" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_security_group" "instance" {
  description = "Security group for public EC2 instance"
  name        = "public-ec2-sg"
  vpc_id      = aws_vpc.main.id

  tags = {
    ManagedBy = var.managed_by_tag
    Name      = "public-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  cidr_ipv4         = var.ssh_ingress_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.instance.id
  to_port           = 22

  tags = {
    ManagedBy = var.managed_by_tag
    Name      = "public-ec2-ssh"
  }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.instance.id

  tags = {
    ManagedBy = var.managed_by_tag
    Name      = "public-ec2-egress-all"
  }
}

resource "aws_instance" "main" {
  ami                         = data.aws_ami.amazon_linux_2.id
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.instance.id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    ManagedBy = var.managed_by_tag
    Name      = "public-ec2"
  }
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Security group ID attached to the instance"
  value       = aws_security_group.instance.id
}