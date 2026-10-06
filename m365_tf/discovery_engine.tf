################################################################################
# Discovery Engine M365 Data Connector Provisioning via setUpDataConnector API
# (Single unified connector with dataSource: "msft")
################################################################################

data "google_client_config" "current" {}

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
    "connectorModes": ["FEDERATED", "ACTIONS"],
    "aclEnabled": false,
    "entities": [
      {"entityName": "enterprise_search"}
    ],
    "params": {
      "auth_token": "placeholder"
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
      "supportedConnectorModes": ["ACTIONS"]
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
