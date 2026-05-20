# Fixes Terraform init failure by ensuring the Google provider block contains only the credential injection placeholder (no region/project/credentials args) while keeping the VPC and two subnetworks unchanged.
# Generated Terraform code for GCP in us-east-1

terraform {
  required_version = ">= 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 7.12.0"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID. Do not set a default; injected/provided by the runtime credentials/environment."
  type        = string
}

variable "private_subnet_cidr" {
  description = "IPv4 CIDR range for the private subnetwork."
  type        = string
  default     = "10.20.0.0/24"
}

variable "private_subnet_name" {
  description = "Name of the private subnetwork (1-63 chars, lowercase, start with a letter; hyphens allowed)."
  type        = string
  default     = "prod-private-subnet"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.private_subnet_name))
    error_message = "private_subnet_name must be 1-63 chars, lowercase, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "private_subnet_region" {
  description = "Region for the private subnetwork (GCP region, e.g., us-east1)."
  type        = string
  default     = "us-east1"
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR range for the public subnetwork."
  type        = string
  default     = "10.10.0.0/24"
}

variable "public_subnet_name" {
  description = "Name of the public subnetwork (1-63 chars, lowercase, start with a letter; hyphens allowed)."
  type        = string
  default     = "prod-public-subnet"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.public_subnet_name))
    error_message = "public_subnet_name must be 1-63 chars, lowercase, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "public_subnet_region" {
  description = "Region for the public subnetwork (GCP region, e.g., us-east1)."
  type        = string
  default     = "us-east1"
}

variable "vpc_name" {
  description = "Name of the VPC network (1-63 chars, lowercase, start with a letter; hyphens allowed)."
  type        = string
  default     = "prod-vpc"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.vpc_name))
    error_message = "vpc_name must be 1-63 chars, lowercase, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

provider "google" {
  {{block_to_replace_cred}}
}

resource "google_compute_network" "vpc" {
  auto_create_subnetworks = false
  name                    = var.vpc_name
  project                 = var.project_id
}

resource "google_compute_subnetwork" "private" {
  ip_cidr_range = var.private_subnet_cidr
  name          = var.private_subnet_name
  network       = google_compute_network.vpc.id
  project       = var.project_id
  region        = var.private_subnet_region
}

resource "google_compute_subnetwork" "public" {
  ip_cidr_range = var.public_subnet_cidr
  name          = var.public_subnet_name
  network       = google_compute_network.vpc.id
  project       = var.project_id
  region        = var.public_subnet_region
}

output "private_subnet_id" {
  description = "ID of the created private subnetwork."
  value       = google_compute_subnetwork.private.id
}

output "public_subnet_id" {
  description = "ID of the created public subnetwork."
  value       = google_compute_subnetwork.public.id
}

output "vpc_id" {
  description = "ID of the created VPC network."
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "Name of the created VPC network."
  value       = google_compute_network.vpc.name
}