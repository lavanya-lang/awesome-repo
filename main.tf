provider "google" {
  {{block_to_replace_cred}}
  region = "us-central1"
}

resource "google_storage_bucket" "this" {
  location      = var.bucket_location
  name          = var.bucket_name
  project       = var.project_id
  storage_class = var.storage_class

  public_access_prevention = "enforced"

  # Ensures compliance with storage.uniformBucketLevelAccess
  uniform_bucket_level_access = true
}