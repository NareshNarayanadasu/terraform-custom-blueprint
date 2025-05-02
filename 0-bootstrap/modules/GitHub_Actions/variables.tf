variable "project_id" {
  description = "The Google Cloud project ID"
}

variable "project_number" {
  description = "The Google Cloud project number"
}

variable "pool_id" {
  default = "github-pool"  # The ID for your Workload Identity Pool
}

variable "provider_id" {
  default = "github-provider"  # The ID for your OIDC provider
}

variable "pool_display_name" {
  default = "GitHub Workload Identity Pool"  # Display name for the pool
}

variable "provider_display_name" {
  default = "GitHub OIDC Provider"  # Display name for the provider
}

variable "pool_description" {
  default = "Federates GitHub Actions with GCP"  # Description for the pool
}

variable "provider_description" {
  default = "OIDC provider for GitHub Actions"  # Description for the provider
}

variable "service_account_id" {
  description = "The service account that GitHub Actions will impersonate"
}
