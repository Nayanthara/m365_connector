# Fetch well-known Microsoft Graph application ID
data "azuread_application_published_app_ids" "well_known" {}

# Query the Microsoft Graph service principal within the customer's Entra directory
data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

# Current Entra client configuration (gives tenant_id)
data "azuread_client_config" "current" {}

locals {
  # Standard redirect URI for Google Vertex AI Search OAuth
  redirect_uri = "https://vertexaisearch.cloud.google.com/console/oauth/default_oauth.html"

  # Base delegated scopes always required by Discovery Engine OAuth
  base_scopes = [
    "offline_access",
    "User.Read"
  ]

  # Granular scope groupings
  users_groups_read_scopes = var.enable_users_groups_read ? [
    "User.ReadBasic.All",
    "Group.Read.All"
  ] : []

  users_groups_action_scopes = var.enable_users_groups_actions ? [
    "Group.ReadWrite.All",
    "GroupMember.ReadWrite.All"
  ] : []

  sharepoint_onedrive_read_scopes = var.enable_sharepoint_onedrive_read ? [
    "Files.Read.All",
    "Sites.Read.All"
  ] : []

  sharepoint_onedrive_action_scopes = var.enable_sharepoint_onedrive_actions ? [
    "Files.ReadWrite.All",
    "Sites.Manage.All",
    "Sites.ReadWrite.All"
  ] : []

  outlook_read_scopes = var.enable_outlook_read ? [
    "Mail.Read",
    "Mail.Read.Shared",
    "Mail.ReadBasic",
    "Calendars.Read",
    "Calendars.Read.Shared",
    "Contacts.Read"
  ] : []

  outlook_action_scopes = var.enable_outlook_actions ? [
    "Mail.Send",
    "Mail.ReadWrite",
    "Mail.ReadWrite.Shared",
    "Calendars.ReadWrite",
    "Calendars.ReadWrite.Shared",
    "Contacts.ReadWrite"
  ] : []

  teams_read_scopes = var.enable_teams_read ? [
    "Chat.Read",
    "Chat.ReadBasic",
    "ChannelMessage.Read.All",
    "Channel.ReadBasic.All",
    "Team.ReadBasic.All",
    "Schedule.Read.All"
  ] : []

  teams_action_scopes = var.enable_teams_actions ? [
    "ChatMessage.Send",
    "Chat.Create",
    "Chat.ReadWrite",
    "ChannelMessage.Send",
    "ChannelMessage.ReadWrite",
    "Channel.Create",
    "ChannelMember.ReadWrite.All",
    "ChannelSettings.ReadWrite.All",
    "TeamSettings.ReadWrite.All",
    "OnlineMeetings.ReadWrite",
    "Schedule.ReadWrite.All"
  ] : []

  # Combined unique list of all delegated permissions
  selected_delegated_permissions = distinct(concat(
    local.base_scopes,
    local.users_groups_read_scopes,
    local.users_groups_action_scopes,
    local.sharepoint_onedrive_read_scopes,
    local.sharepoint_onedrive_action_scopes,
    local.outlook_read_scopes,
    local.outlook_action_scopes,
    local.teams_read_scopes,
    local.teams_action_scopes
  ))

  # Resolve scope IDs from Microsoft Graph service principal
  msgraph_oauth2_permissions_map = {
    for p in data.azuread_service_principal.msgraph.oauth2_permission_scopes :
    p.value => p.id
  }
}

################################################################################
# Microsoft Entra App Registration
################################################################################

resource "azuread_application" "m365_connector" {
  display_name     = var.entra_app_display_name
  sign_in_audience = "AzureADMyOrg" # Accounts in this organizational directory only

  web {
    redirect_uris = [local.redirect_uri]
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    dynamic "resource_access" {
      for_each = local.selected_delegated_permissions
      content {
        id   = local.msgraph_oauth2_permissions_map[resource_access.value]
        type = "Scope" # Delegated permission
      }
    }
  }
}

################################################################################
# Enterprise Application (Service Principal in Tenant)
################################################################################

resource "azuread_service_principal" "m365_connector" {
  client_id                    = azuread_application.m365_connector.client_id
  app_role_assignment_required = false
}

################################################################################
# Client Secret
################################################################################

resource "time_offset" "secret_expiration" {
  offset_days = var.client_secret_valid_days
}

resource "azuread_application_password" "client_secret" {
  application_id = azuread_application.m365_connector.id
  display_name   = "DiscoveryEngine-M365-Secret"
  end_date       = time_offset.secret_expiration.rfc3339
}
