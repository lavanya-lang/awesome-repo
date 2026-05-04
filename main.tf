# Creates a production-grade Google Cloud KMS Key Ring and CryptoKey for encrypting sensitive data at rest, with rotation enabled, prevent_destroy lifecycle protection, least-privilege IAM bindings (admin, encrypter/decrypter, viewer), and labels environment=production and managed_by=terraform.
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
  description = "GCP project ID where the KMS resources will be created."
  type        = string
}

variable "location" {
  description = "KMS location. Use a GCP KMS location (region like us-east1) or multi-region (like us). Note: the provided target region 'us-east-1' is an AWS-style region and is not valid in GCP."
  type        = string
  default     = "us-east1"
}

variable "key_ring_name" {
  description = "Name of the Cloud KMS Key Ring."
  type        = string
  default     = "prod-data-keyring"

  validation {
    condition     = length(var.key_ring_name) > 0
    error_message = "key_ring_name must not be empty."
  }
}

variable "crypto_key_name" {
  description = "Name of the Cloud KMS CryptoKey used to encrypt sensitive production data at rest."
  type        = string
  default     = "prod-data-key"

  validation {
    condition     = length(var.crypto_key_name) > 0
    error_message = "crypto_key_name must not be empty."
  }
}

variable "kms_key_admins" {
  description = "List of IAM members who can administer the key (e.g., [\"group:secops@example.com\"])."
  type        = list(string)
  default     = []
}

variable "kms_key_encrypters_decrypters" {
  description = "List of IAM members allowed to encrypt/decrypt using the key (e.g., [\"serviceAccount:app-sa@PROJECT_ID.iam.gserviceaccount.com\"])."
  type        = list(string)
  default     = []
}

variable "kms_key_viewers" {
  description = "List of IAM members allowed to view key metadata (least-privilege read-only)."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to supported resources."
  type        = map(string)
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}

provider "google" {
  {{block_to_replace_cred}}
}

resource "google_kms_key_ring" "prod" {
  location = var.location
  name     = var.key_ring_name
  project  = var.project_id
}

resource "google_kms_crypto_key" "prod_data" {
  key_ring = google_kms_key_ring.prod.id
  name     = var.crypto_key_name

  labels = var.labels

  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "admins" {
  crypto_key_id = google_kms_crypto_key.prod_data.id
  members       = var.kms_key_admins
  role          = "roles/cloudkms.admin"
}

resource "google_kms_crypto_key_iam_binding" "encrypters_decrypters" {
  crypto_key_id = google_kms_crypto_key.prod_data.id
  members       = var.kms_key_encrypters_decrypters
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_kms_crypto_key_iam_binding" "viewers" {
  crypto_key_id = google_kms_crypto_key.prod_data.id
  members       = var.kms_key_viewers
  role          = "roles/cloudkms.viewer"
}

output "kms_location" {
  description = "KMS location used for the Key Ring and CryptoKey."
  value       = var.location
}

output "key_ring_id" {
  description = "ID of the Cloud KMS Key Ring."
  value       = google_kms_key_ring.prod.id
}

output "crypto_key_id" {
  description = "ID of the Cloud KMS CryptoKey."
  value       = google_kms_crypto_key.prod_data.id
}

output "crypto_key_name" {
  description = "Name of the Cloud KMS CryptoKey."
  value       = google_kms_crypto_key.prod_data.name
}