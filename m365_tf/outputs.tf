################################################################################
# Microsoft Entra Outputs
################################################################################

output "entra_tenant_id" {
  description = "The Tenant ID of your Microsoft 365 tenant."
  value       = data.azuread_client_config.current.tenant_id
}

output "entra_application_id" {
  description = "The Client ID of the registered Microsoft Entra application."
  value       = azuread_application.m365_connector.client_id
}

output "entra_client_secret" {
  description = "The generated client secret for the Microsoft Entra application."
  value       = azuread_application_password.client_secret.value
  sensitive   = true
}

output "granted_delegated_permissions" {
  description = "List of Microsoft Graph delegated permissions configured on the Entra app."
  value       = local.selected_delegated_permissions
}

################################################################################
# GCP Outputs
################################################################################

output "gcp_secret_id" {
  description = "The resource ID of the Secret Manager secret storing the M365 credentials."
  value       = google_secret_manager_secret.m365_credentials.id
}

output "discovery_engine_data_store_id" {
  description = "The Discovery Engine data store ID."
  value       = var.data_store_id
}

output "discovery_engine_data_store_name" {
  description = "The full resource name of the Discovery Engine data store."
  value       = "projects/${var.project_id}/locations/${var.location}/collections/${var.collection_id}/dataStores/${var.data_store_id}"
}

output "discovery_engine_service_agent" {
  description = "The service agent account for Discovery Engine."
  value       = local.discovery_engine_service_agent
}

################################################################################
# Verification / Consent Handoff Output
################################################################################

locals {
  auth_host = var.o365_environment_type == "us" ? "login.microsoftonline.us" : "login.microsoftonline.com"
  scopes_encoded = urlencode(join(" ", local.selected_delegated_permissions))
}

output "microsoft_consent_verification_url" {
  description = "Direct URL to grant tenant admin consent / authorize the account for the connector with the configured scopes."
  value       = "https://${local.auth_host}/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/authorize?client_id=${azuread_application.m365_connector.client_id}&response_type=code&redirect_uri=${urlencode(local.redirect_uri)}&prompt=consent&scope=${local.scopes_encoded}"
}

output "console_setup_instructions" {
  description = "Steps to complete the one-click verification in Google Cloud Console."
  value       = <<-EOT
    1. In the Google Cloud Console, open Vertex AI Search & Conversation / Discovery Engine:
       https://console.cloud.google.com/gen-app-builder/engines?project=${var.project_id}
    2. Go to 'Data stores' -> select '${var.data_store_display_name}' (ID: ${var.data_store_id}).
    3. In Authentication Settings:
       - Tenant ID: ${data.azuread_client_config.current.tenant_id}
       - Client ID: ${azuread_application.m365_connector.client_id}
       - Client Secret: (Retrieved from Secret Manager: ${var.secret_name})
       - Environment: ${var.o365_environment_type == "us" ? "US Government" : "Standard"}
    4. Click 'Verify Auth' to sign in with your Microsoft 365 administrator account and grant consent.
  EOT
}
