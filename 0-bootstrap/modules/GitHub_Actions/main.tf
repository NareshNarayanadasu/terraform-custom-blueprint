###  Enable Required APIs

resource "google_project_service" "services" {
  project            = var.project_id  # The GCP project ID
  count              = length(var.service_list)  # Number of services to enable
  service            = var.service_list[count.index]  # The service to enable
  disable_on_destroy = false  # Services will remain enabled even if this resource is destroyed
}


## service_list contains the list of GCP APIs you need to enable, like IAM and STS APIs.
variable "service_list" {
  default = [
    "iam.googleapis.com",  # Enables IAM API
    "sts.googleapis.com"   # Enables the Security Token Service (STS) API
  ]
}


### Create Workload Identity Pool

resource "google_iam_workload_identity_pool" "main" {
  project                    = var.project_id  # The project ID in which the pool will be created
  workload_identity_pool_id = var.pool_id  # Unique ID for the identity pool
  display_name              = var.pool_display_name  # A user-friendly name for the pool
  description               = var.pool_description  # A brief description for the pool
  disabled                  = false  # Ensures the pool is enabled
}


### Configure OIDC Provider for GitHub Actions

resource "google_iam_workload_identity_pool_provider" "main" {
  project                            = var.project_id  # The GCP project ID
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id  # The identity pool ID created in the previous step
  workload_identity_pool_provider_id = var.provider_id  # Unique ID for the provider
  display_name                       = var.provider_display_name  # A user-friendly name for the provider
  description                        = var.provider_description  # A description for the provider

  # Mapping external claims (from GitHub Actions) to GCP attributes
  attribute_mapping = {
    "google.subject"          = "assertion.sub"  # Map 'sub' from GitHub token to 'google.subject' in GCP
    "attribute.actor"         = "assertion.actor"  # GitHub actor (user or bot)
    "attribute.repository"    = "assertion.repository"  # The GitHub repository
    "attribute.repository_owner" = "assertion.repository_owner"  # The owner of the GitHub repository
    "attribute.workflow"      = "assertion.workflow"  # The GitHub Actions workflow name
    "attribute.ref"           = "assertion.ref"  # The GitHub branch or commit ref
    "attribute.sha"           = "assertion.sha"  # The commit hash of the current GitHub Action run
  }

  # Attribute condition to restrict access to a specific GitHub repository
  attribute_condition = "assertion.repository == 'your-org/your-repo'"  # Replace with your GitHub repository name

  # OIDC configuration for GitHub Actions
  oidc {
    issuer_uri        = "https://token.actions.githubusercontent.com"  # OIDC issuer URI for GitHub Actions
    allowed_audiences = ["https://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.pool_id}/providers/${var.provider_id}"]  # Allowed audience for the token
  }
}
## This resource grants permission for GitHub Actions to impersonate a Google Cloud service account by assigning the roles/iam.workloadIdentityUser role to the GitHub identities.

resource "google_service_account_iam_member" "wif_sa" {
  service_account_id = var.service_account_id  # The service account that GitHub Actions will impersonate
  role               = "roles/iam.workloadIdentityUser"  # Role allowing impersonation of the service account
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.repository/your-org/your-repo"  # Specifies the GitHub repository as the principal
}
