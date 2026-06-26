output "google_storage_bucket_id" {
  description = "The bucket resource ID."
  value       = google_storage_bucket.this.id
}

output "google_storage_bucket_name" {
  description = "The bucket name."
  value       = google_storage_bucket.this.name
}

output "google_storage_bucket_self_link" {
  description = "The bucket self link."
  value       = google_storage_bucket.this.self_link
}