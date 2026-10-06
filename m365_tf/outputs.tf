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

output "enabled_connector_actions" {
  description = "List of action IDs enabled on the Microsoft 365 BAP data connector."
  value       = local.selected_enabled_actions
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
       Your Data Store '${var.data_store_id}' (${var.data_store_display_name}) is active with ${length(local.selected_enabled_actions)} enabled tool actions.
    3. Tenant Admin Consent / Authorization:
       - Open the consent verification URL to sign in with your Microsoft 365 administrator account and grant consent:
         https://${local.auth_host}/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/authorize?client_id=${azuread_application.m365_connector.client_id}&response_type=code&redirect_uri=${urlencode(local.redirect_uri)}&prompt=consent&scope=${local.scopes_encoded}
       - Note: After clicking 'Accept', you can safely ignore any redirect error/warning on the callback page (such as "Couldn't connect your data source" or "Connecting your instance..."). Microsoft Entra records the granted consent before redirecting.
       - You can verify the granted permissions in Microsoft Entra Admin Center:
         https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnApi/appId/${azuread_application.m365_connector.client_id}/isGateway~/false
    4. Enable Tools in Gemini Enterprise / Vertex AI Search App:
       - In your Gemini Enterprise / Vertex AI Search App (e.g. Engine '${var.engine_id != "" ? var.engine_id : "<engine_id>"}'), navigate to Configurations -> Tools / Extensions / Actions.
       - The Microsoft 365 connector tools are now registered and can be toggled on for your Assistant.
  EOT
}
