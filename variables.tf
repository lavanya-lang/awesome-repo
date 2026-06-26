variable "bucket_location" {
  description = "GCS bucket location (region, dual-region, or multi-region)."
  type        = string
  default     = "US-CENTRAL1"

  validation {
    condition     = length(var.bucket_location) > 0
    error_message = "bucket_location must be a non-empty string."
  }
}

variable "bucket_name" {
  description = "Globally-unique GCS bucket name."
  type        = string
  default     = "gcp-demo-storage-2026"

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name must be between 3 and 63 characters."
  }
}

variable "project_id" {
  description = "GCP Project ID (provided by credentials in this environment)."
  type        = string
}

variable "storage_class" {
  description = "GCS storage class."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "storage_class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}