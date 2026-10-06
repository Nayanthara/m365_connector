################################################################################
# Discovery Engine M365 Data Connector Provisioning via setUpDataConnector API
# (Single unified connector with dataSource: "msft")
################################################################################

data "google_client_config" "current" {}

locals {
  # Granular M365 action lists matching registry actions (dataSource: "msft")
  users_groups_read_actions = var.enable_users_groups_read ? [
    "entra_get_user",
    "entra_list_groups",
    "entra_list_users",
    "get_my_profile"
  ] : []

  users_groups_action_actions = var.enable_users_groups_actions ? [
    "entra_add_group_member",
    "entra_add_group_owner",
    "entra_create_group",
    "entra_update_group"
  ] : []

  sharepoint_onedrive_read_actions = var.enable_sharepoint_onedrive_read ? [
    "excel_get_row",
    "excel_get_rows",
    "excel_get_tables",
    "excel_get_workbook",
    "excel_get_worksheet",
    "excel_get_worksheets",
    "excel_list_workbooks",
    "files_get_item_content",
    "files_list_children",
    "files_list_permissions",
    "sharepoint_get_list_item",
    "sharepoint_get_page_content",
    "sharepoint_list_list_items",
    "sharepoint_list_lists",
    "sharepoint_search"
  ] : []

  sharepoint_onedrive_action_actions = var.enable_sharepoint_onedrive_actions ? [
    "excel_add_table_column",
    "excel_add_table_rows",
    "excel_create_table",
    "excel_create_worksheet",
    "excel_update_table_row",
    "files_check_in_document",
    "files_check_out_document",
    "files_copy_file",
    "files_copy_folder",
    "files_create_file",
    "files_create_folder",
    "files_create_share_link",
    "files_discard_check_out_document",
    "files_move_file",
    "files_move_folder",
    "files_rename_file",
    "files_rename_folder",
    "files_replace_file",
    "files_send_share_invite",
    "files_update_file_properties",
    "sharepoint_create_list",
    "sharepoint_create_list_item",
    "sharepoint_create_page",
    "sharepoint_update_list",
    "sharepoint_update_list_item",
    "sharepoint_update_page"
  ] : []

  outlook_read_actions = var.enable_outlook_read ? [
    "outlook_find_meeting_times",
    "outlook_get_attachment",
    "outlook_get_event",
    "outlook_get_message",
    "outlook_get_schedule",
    "outlook_list_calendar_view",
    "outlook_list_calendars",
    "outlook_list_contacts",
    "outlook_list_mail_folders",
    "outlook_list_messages",
    "outlook_list_shared_mailbox_messages",
    "outlook_search_email",
    "outlook_search_events"
  ] : []

  outlook_action_actions = var.enable_outlook_actions ? [
    "outlook_add_attachment",
    "outlook_create_calendar",
    "outlook_create_contact",
    "outlook_create_draft_message",
    "outlook_create_event",
    "outlook_create_reply_draft",
    "outlook_forward_message",
    "outlook_move_message",
    "outlook_reply_all_message",
    "outlook_reply_message",
    "outlook_rsvp_to_event",
    "outlook_send_draft_message",
    "outlook_send_mail",
    "outlook_update_calendar",
    "outlook_update_contact",
    "outlook_update_event",
    "outlook_update_message"
  ] : []

  teams_read_actions = var.enable_teams_read ? [
    "teams_list_channel_messages",
    "teams_list_channels",
    "teams_list_chat_messages",
    "teams_list_chats",
    "teams_list_joined_teams",
    "teams_list_message_replies",
    "teams_list_scheduling_groups",
    "teams_list_time_off_entries",
    "teams_list_time_off_reasons",
    "teams_search_messages"
  ] : []

  teams_action_actions = var.enable_teams_actions ? [
    "teams_add_channel_member",
    "teams_create_channel",
    "teams_create_chat",
    "teams_create_meeting",
    "teams_create_scheduling_group",
    "teams_create_time_off_entry",
    "teams_create_time_off_reason",
    "teams_reply_to_channel_message",
    "teams_send_channel_message",
    "teams_send_chat_message",
    "teams_update_channel",
    "teams_update_channel_message",
    "teams_update_chat",
    "teams_update_chat_message",
    "teams_update_scheduling_group",
    "teams_update_team",
    "teams_update_time_off_entry"
  ] : []

  # Combined unique list of enabled action IDs to expose via BAP
  selected_enabled_actions = distinct(concat(
    local.users_groups_read_actions,
    local.users_groups_action_actions,
    local.sharepoint_onedrive_read_actions,
    local.sharepoint_onedrive_action_actions,
    local.outlook_read_actions,
    local.outlook_action_actions,
    local.teams_read_actions,
    local.teams_action_actions
  ))
}

resource "terraform_data" "setup_m365_connector" {
  input = {
    project_id            = var.project_id
    location              = var.location
    collection_id         = var.collection_id
    data_store_id         = var.data_store_id
    display_name          = var.data_store_display_name
    connector_mode        = var.connector_mode
    instance_uri          = var.instance_uri
    client_id             = azuread_application.m365_connector.client_id
    tenant_id             = data.azuread_client_config.current.tenant_id
    client_secret         = azuread_application_password.client_secret.value
    o365_environment_type = var.o365_environment_type
    azure_host_url        = local.azure_host_url
    engine_id             = var.engine_id
    enabled_actions       = jsonencode(local.selected_enabled_actions)
  }

  provisioner "local-exec" {
    command = <<EOT
set -e

ACCESS_TOKEN="${data.google_client_config.current.access_token}"
if [ -z "$ACCESS_TOKEN" ]; then
  ACCESS_TOKEN=$(gcloud auth print-access-token)
fi

PROJECT_ID="${self.input.project_id}"
LOCATION="${self.input.location}"
COLLECTION_ID="${self.input.collection_id}"
DATA_STORE_ID="${self.input.data_store_id}"
DISPLAY_NAME="${self.input.display_name}"
MODE="${self.input.connector_mode}"
INSTANCE_URI="${self.input.instance_uri}"
CLIENT_ID="${self.input.client_id}"
CLIENT_SECRET="${self.input.client_secret}"
TENANT_ID="${self.input.tenant_id}"
O365_ENV="${self.input.o365_environment_type}"
AZURE_HOST_URL="${self.input.azure_host_url}"
ENGINE_ID="${self.input.engine_id}"
ENABLED_ACTIONS_JSON='${self.input.enabled_actions}'

# 1. Clean up any existing empty/generic data store with this ID before calling setUpDataConnector
DATASTORE_URL="https://discoveryengine.googleapis.com/v1alpha/projects/$PROJECT_ID/locations/$LOCATION/collections/$COLLECTION_ID/dataStores/$DATA_STORE_ID"
CHECK_CODE=$(curl -s -o /dev/null -w "%%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-Goog-User-Project: $PROJECT_ID" \
  "$DATASTORE_URL")

if [ "$CHECK_CODE" = "200" ]; then
  echo "Found existing Data Store '$DATA_STORE_ID'. Deleting before provisioning M365 connector..."
  curl -s -X DELETE \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-Goog-User-Project: $PROJECT_ID" \
    "$DATASTORE_URL" > /dev/null
  echo "Waiting 10s for deletion to settle..."
  sleep 10
fi

# 2. Build M365 connector (dataSource: msft) payload
PAYLOAD=$(cat <<JSON
{
  "collectionId": "$DATA_STORE_ID",
  "collectionDisplayName": "$DISPLAY_NAME",
  "dataConnector": {
    "dataSource": "msft",
    "dataSourceVersion": 1,
    "connectorSourceId": "msft",
    "connectorModes": ["FEDERATED", "ACTIONS"],
    "aclEnabled": false,
    "entities": [
      {"entityName": "enterprise_search"}
    ],
    "params": {
      "auth_token": "placeholder",
      "o365_environment_type": "$O365_ENV"
    },
    "actionConfig": {
      "actionParams": {
        "auth_key": "ByoOAuth",
        "auth_type": "OAUTH",
        "client_id": "$CLIENT_ID",
        "client_secret": "$CLIENT_SECRET",
        "tenant_id": "$TENANT_ID",
        "o365_environment_type": "$O365_ENV",
        "azure_host_url": "$AZURE_HOST_URL"
      },
      "createBapConnection": true,
      "isActionConfigured": true
    },
    "bapConfig": {
      "supportedConnectorModes": ["ACTIONS"],
      "enabledActions": $ENABLED_ACTIONS_JSON
    },
    "refreshInterval": "7200s",
    "syncMode": "PERIODIC"
  }
}
JSON
)

echo "Calling Discovery Engine setUpDataConnector API for M365 connector '$DATA_STORE_ID' (dataSource: msft)..."
RESPONSE=$(curl -s -w "\n%%{http_code}" -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: $PROJECT_ID" \
  -d "$PAYLOAD" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/$PROJECT_ID/locations/$LOCATION:setUpDataConnector")

HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
  echo "setUpDataConnector for M365 submitted successfully (HTTP $HTTP_STATUS)."
else
  echo "setUpDataConnector API error (HTTP $HTTP_STATUS): $BODY"
  exit 1
fi

if [ -n "$ENGINE_ID" ]; then
  echo "Binding Data Store to Engine '$ENGINE_ID'..."
  curl -s -X POST \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-Goog-User-Project: $PROJECT_ID" \
    "https://discoveryengine.googleapis.com/v1alpha/projects/$PROJECT_ID/locations/$LOCATION/collections/$COLLECTION_ID/engines/$ENGINE_ID/dataStores?dataStoreId=$DATA_STORE_ID"
fi
EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
ACCESS_TOKEN=$(gcloud auth print-access-token 2>/dev/null || true)
if [ -n "$ACCESS_TOKEN" ]; then
  echo "Deleting Discovery Engine Data Store '${self.input.data_store_id}'..."
  curl -s -X DELETE \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-Goog-User-Project: ${self.input.project_id}" \
    "https://discoveryengine.googleapis.com/v1alpha/projects/${self.input.project_id}/locations/${self.input.location}/collections/${self.input.collection_id}/dataStores/${self.input.data_store_id}" > /dev/null || true
fi
EOT
  }

  depends_on = [
    azuread_application.m365_connector,
    azuread_application_password.client_secret,
    azuread_service_principal.m365_connector,
    google_secret_manager_secret_version.m365_credentials_version,
  ]
}
