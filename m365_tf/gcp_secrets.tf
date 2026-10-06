data "google_project" "current" {
  project_id = var.project_id
}

locals {
  # Google Cloud Discovery Engine service agent identity
  discovery_engine_service_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-discoveryengine.iam.gserviceaccount.com"

  # Structured credentials payload formatted for Discovery Engine M365 connector
  connector_credentials_payload = jsonencode({
    tenant_id              = data.azuread_client_config.current.tenant_id
    client_id              = azuread_application.m365_connector.client_id
    client_secret          = azuread_application_password.client_secret.value
    o365_environment_type  = var.o365_environment_type
    azure_host_url         = lookup({
      "Standard / GCC" = "https://graph.microsoft.com",
      "GCC High"       = "https://graph.microsoft.us",
      "DoD"            = "https://dod-graph.microsoft.us"
    }, var.o365_cloud_environment, "https://graph.microsoft.com")
  })
}

################################################################################
# Secret Manager: M365 Credentials
################################################################################

resource "google_secret_manager_secret" "m365_credentials" {
  project   = var.project_id
  secret_id = var.secret_name

  replication {
    auto {}
  }

  labels = {
    managed-by = "terraform"
    connector  = "microsoft-365"
  }
}

resource "google_secret_manager_secret_version" "m365_credentials_version" {
  secret      = google_secret_manager_secret.m365_credentials.id
  secret_data = local.connector_credentials_payload
}

################################################################################
# IAM: Grant Discovery Engine Service Agent Access to Secret
################################################################################

resource "google_secret_manager_secret_iam_member" "discovery_engine_access" {
  count     = var.grant_discovery_engine_secret_access ? 1 : 0
  project   = var.project_id
  secret_id = google_secret_manager_secret.m365_credentials.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = local.discovery_engine_service_agent
}

