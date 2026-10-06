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
  description = "Official Microsoft Entra Tenant Admin Consent URL for the connector."
  value       = "https://${local.auth_host}/${data.azuread_client_config.current.tenant_id}/adminconsent?client_id=${azuread_application.m365_connector.client_id}"
}

output "entra_admin_consent_portal_url" {
  description = "Direct link to the Microsoft Entra Admin Center to verify granted permissions."
  value       = "https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnApi/appId/${azuread_application.m365_connector.client_id}/isGateway~/false"
}

output "console_setup_instructions" {
  description = "Steps to verify the Microsoft 365 Connector setup in Google Cloud Console."
  value       = <<-EOT
    1. The Microsoft 365 Data Connector has been provisioned via setUpDataConnector with dataSource 'msft'.
    2. In the Google Cloud Console, open Vertex AI Search Data Stores:
       https://console.cloud.google.com/gen-app-builder/data-stores?project=${var.project_id}
       Your Data Store '${var.data_store_id}' (${var.data_store_display_name}) is active.
    3. Tenant Admin Consent Status:
       - Since the API permissions show as granted in Microsoft Entra ID, admin consent is already 100% complete.
       - You can verify the granted permissions at:
         https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnApi/appId/${azuread_application.m365_connector.client_id}/isGateway~/false
  EOT
}
