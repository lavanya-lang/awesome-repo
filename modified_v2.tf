# Creates a custom-mode GCP VPC network with one public and one private subnetwork in a single region. Includes variables for project_id, region, and subnet CIDR ranges, and does not create google_project resources.
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
  description = "GCP Project ID (provided by credentials/runtime)."
  type        = string
}

variable "region" {
  description = "GCP region for regional resources (e.g., us-east1)."
  type        = string
  default     = "us-east1"
  validation {
    condition     = can(regex("^[a-z]+-[a-z0-9]+[0-9]$", var.region))
    error_message = "region must look like a GCP region, e.g., us-east1."
  }
}

variable "network_name" {
  description = "Name of the custom-mode VPC network (lowercase, 1-63 chars, starts with a letter)."
  type        = string
  default     = "main-vpc"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.network_name))
    error_message = "network_name must be lowercase, 1-63 chars, start with a letter, and contain only letters, digits, and hyphens."
  }
}

variable "public_subnet_name" {
  description = "Name of the public subnet (lowercase, 1-63 chars, starts with a letter)."
  type        = string
  default     = "public-subnet"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.public_subnet_name))
    error_message = "public_subnet_name must be lowercase, 1-63 chars, start with a letter, and contain only letters, digits, and hyphens."
  }
}

variable "private_subnet_name" {
  description = "Name of the private subnet (lowercase, 1-63 chars, starts with a letter)."
  type        = string
  default     = "private-subnet"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.private_subnet_name))
    error_message = "private_subnet_name must be lowercase, 1-63 chars, start with a letter, and contain only letters, digits, and hyphens."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet (e.g., 10.10.0.0/24)."
  type        = string
  default     = "10.10.0.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private subnet (e.g., 10.10.1.0/24)."
  type        = string
  default     = "10.10.1.0/24"
}

provider "google" {
  {{block_to_replace_cred}}
  region  = var.region
}

resource "google_compute_network" "main" {
  auto_create_subnetworks = false
  name                    = var.network_name
  project                 = var.project_id
}

resource "google_compute_subnetwork" "public" {
  ip_cidr_range = var.public_subnet_cidr
  name          = var.public_subnet_name
  network       = google_compute_network.main.id
  project       = var.project_id
  region        = var.region
}

resource "google_compute_subnetwork" "private" {
  ip_cidr_range = var.private_subnet_cidr
  name          = var.private_subnet_name
  network       = google_compute_network.main.id
  project       = var.project_id
  region        = var.region
}

output "network_id" {
  description = "ID of the VPC network."
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "Name of the VPC network."
  value       = google_compute_network.main.name
}

output "public_subnet_id" {
  description = "ID of the public subnetwork."
  value       = google_compute_subnetwork.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnetwork."
  value       = google_compute_subnetwork.private.id
}

output "public_subnet_self_link" {
  description = "Self link of the public subnetwork."
  value       = google_compute_subnetwork.public.self_link
}

output "private_subnet_self_link" {
  description = "Self link of the private subnetwork."
  value       = google_compute_subnetwork.private.self_link
}