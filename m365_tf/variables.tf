################################################################################
# General / Identity Variables
################################################################################

variable "project_id" {
  type        = string
  description = "The Google Cloud Project ID where Discovery Engine and Secret Manager resources reside."
}

variable "location" {
  type        = string
  description = "The Discovery Engine location for the data store. Valid values: 'global', 'us', 'eu'."
  default     = "global"

  validation {
    condition     = contains(["global", "us", "eu"], var.location)
    error_message = "Location must be one of: 'global', 'us', or 'eu'."
  }
}

variable "collection_id" {
  type        = string
  description = "The Collection ID for the Discovery Engine data connector and data store."
  default     = "default_collection"
}

variable "data_store_id" {
  type        = string
  description = "The unique ID of the Discovery Engine data store to create for Microsoft 365."
  default     = "ms-365-datastore"
}

variable "data_store_display_name" {
  type        = string
  description = "Display name for the Discovery Engine data store."
  default     = "Microsoft 365"
}

variable "connector_type" {
  type        = string
  description = "Microsoft 365 connector type to provision: 'sharepoint', 'onedrive', 'outlook', 'teams', or 'custom_mcp'."
  default     = "sharepoint"

  validation {
    condition     = contains(["sharepoint", "onedrive", "outlook", "teams", "custom_mcp"], var.connector_type)
    error_message = "connector_type must be one of: 'sharepoint', 'onedrive', 'outlook', 'teams', or 'custom_mcp'."
  }
}

variable "connector_mode" {
  type        = string
  description = "Connector architecture mode: 'FEDERATED' (search & actions via API) or 'DATA_INGESTION' (batch sync/crawl with ACLs)."
  default     = "FEDERATED"

  validation {
    condition     = contains(["FEDERATED", "DATA_INGESTION"], var.connector_mode)
    error_message = "connector_mode must be either 'FEDERATED' or 'DATA_INGESTION'."
  }
}

variable "instance_uri" {
  type        = string
  description = "The SharePoint Online or OneDrive instance URL (e.g. https://acme.sharepoint.com). Required for sharepoint and onedrive connectors."
  default     = ""
}

variable "tenant_domain" {
  type        = string
  description = "The tenant domain for Microsoft Teams (e.g. acme.onmicrosoft.com). Optional."
  default     = ""
}

variable "engine_id" {
  type        = string
  description = "Optional Discovery Engine / Gemini Enterprise Engine ID to link the data store to."
  default     = ""
}

################################################################################
# Microsoft Entra (Azure AD) App Registration Variables
################################################################################

variable "entra_app_display_name" {
  type        = string
  description = "Display name of the registered Microsoft Entra application."
  default     = "Google Vertex AI Search M365 Connector"
}

variable "client_secret_valid_days" {
  type        = number
  description = "Number of days the Microsoft Entra client secret remains valid."
  default     = 365
}

################################################################################
# Environment & Sovereign Cloud Variables
################################################################################

variable "o365_environment_type" {
  type        = string
  description = "Microsoft 365 Environment Type for sign-in: 'com' (Standard: login.microsoftonline.com) or 'us' (US Government: login.microsoftonline.us)."
  default     = "com"

  validation {
    condition     = contains(["com", "us"], var.o365_environment_type)
    error_message = "o365_environment_type must be either 'com' or 'us'."
  }
}

variable "o365_cloud_environment" {
  type        = string
  description = "Microsoft 365 Cloud Environment for Microsoft Graph API: 'Standard / GCC' (https://graph.microsoft.com), 'GCC High' (https://graph.microsoft.us), or 'DoD' (https://dod-graph.microsoft.us)."
  default     = "Standard / GCC"

  validation {
    condition     = contains(["Standard / GCC", "GCC High", "DoD"], var.o365_cloud_environment)
    error_message = "o365_cloud_environment must be one of: 'Standard / GCC', 'GCC High', or 'DoD'."
  }
}

################################################################################
# Granular Scope Toggles (Read vs. Action for each M365 Surface)
################################################################################

# --- Users & Groups ---
variable "enable_users_groups_read" {
  type        = bool
  description = "Enable read permissions for Microsoft Entra Users & Groups (User.Read, User.ReadBasic.All, Group.Read.All)."
  default     = true
}

variable "enable_users_groups_actions" {
  type        = bool
  description = "Enable management/action permissions for Microsoft Entra Groups (Group.ReadWrite.All, GroupMember.ReadWrite.All)."
  default     = false
}

# --- SharePoint & OneDrive ---
variable "enable_sharepoint_onedrive_read" {
  type        = bool
  description = "Enable read permissions for SharePoint & OneDrive (Files.Read.All, Sites.Read.All)."
  default     = true
}

variable "enable_sharepoint_onedrive_actions" {
  type        = bool
  description = "Enable file & site action permissions for SharePoint & OneDrive (Files.ReadWrite.All, Sites.Manage.All, Sites.ReadWrite.All)."
  default     = false
}

# --- Outlook (Mail & Calendars & Contacts) ---
variable "enable_outlook_read" {
  type        = bool
  description = "Enable read permissions for Outlook Mail, Calendars, and Contacts (Mail.Read, Mail.Read.Shared, Mail.ReadBasic, Calendars.Read, Calendars.Read.Shared, Contacts.Read)."
  default     = true
}

variable "enable_outlook_actions" {
  type        = bool
  description = "Enable action/send permissions for Outlook Mail, Calendars, and Contacts (Mail.Send, Mail.ReadWrite, Mail.ReadWrite.Shared, Calendars.ReadWrite, Calendars.ReadWrite.Shared, Contacts.ReadWrite)."
  default     = false
}

# --- Teams ---
variable "enable_teams_read" {
  type        = bool
  description = "Enable read permissions for Microsoft Teams (Chat.Read, Chat.ReadBasic, ChannelMessage.Read.All, Channel.ReadBasic.All, Team.ReadBasic.All, Schedule.Read.All)."
  default     = true
}

variable "enable_teams_actions" {
  type        = bool
  description = "Enable action permissions for Microsoft Teams (ChatMessage.Send, Chat.Create, Chat.ReadWrite, ChannelMessage.Send, ChannelMessage.ReadWrite, Channel.Create, ChannelMember.ReadWrite.All, ChannelSettings.ReadWrite.All, TeamSettings.ReadWrite.All, OnlineMeetings.ReadWrite, Schedule.ReadWrite.All)."
  default     = false
}

################################################################################
# GCP Secret Manager Configuration
################################################################################

variable "secret_name" {
  type        = string
  description = "Name of the Google Secret Manager secret used to store the M365 connector credentials."
  default     = "discovery-engine-msft-credentials"
}
