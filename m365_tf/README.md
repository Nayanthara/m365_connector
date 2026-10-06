# Terraform Template for Gemini Enterprise Microsoft 365 Connector

This Terraform module automates the setup of the **Microsoft 365 Connector** for Gemini Enterprise.

## What This Module Does

1. **Microsoft Entra (Azure AD) App Registration**:
   - Registers an OAuth 2.0 Web Application with redirect URIs `https://vertexaisearch.cloud.google.com/oauth-redirect` and `https://vertexaisearch.cloud.google.com/console/oauth/default_oauth.html`.
   - Generates a secure client secret with configurable validity (`client_secret_valid_days`).
   - Automatically maps and attaches delegated Microsoft Graph API permissions based on your granular Read vs. Action toggles.
   - Creates the Enterprise Application / Service Principal in your tenant.

2. **Granular Permissions (Read vs. Action)**:
   - **Users & Groups**: `enable_users_groups_read`, `enable_users_groups_actions`
   - **SharePoint & OneDrive**: `enable_sharepoint_onedrive_read`, `enable_sharepoint_onedrive_actions`
   - **Outlook (Mail & Calendar & Contacts)**: `enable_outlook_read`, `enable_outlook_actions`
   - **Teams**: `enable_teams_read`, `enable_teams_actions`

3. **Cloud Environment & Sovereign Clouds**:
   - `o365_environment_type`: `"com"` (`login.microsoftonline.com`) or `"us"` (`login.microsoftonline.us`).
   - `o365_cloud_environment`: `"Standard / GCC"` (`https://graph.microsoft.com`), `"GCC High"` (`https://graph.microsoft.us`), or `"DoD"` (`https://dod-graph.microsoft.us`).

4. **Google Secret Manager Credential Vaulting**:
   - Creates a Google Secret Manager secret containing the structured credentials payload (`tenant_id`, `client_id`, `client_secret`, `o365_environment_type`, `azure_host_url`).
   - Grants the Discovery Engine service agent (`service-<project-number>@gcp-sa-discoveryengine.iam.gserviceaccount.com`) Secret Accessor permissions.

5. **Automated Discovery Engine Data Connector Provisioning & Tool Registration**:
   - Calls Discovery Engine's `setUpDataConnector` API with `dataSource: "msft"` to provision the single unified Microsoft 365 connector (supporting both `FEDERATED` and `DATA_INGESTION` modes).
   - Dynamically registers all selected action IDs via `bapConfig.enabledActions` (up to 106 tools covering Outlook search/mail/calendar/contacts, SharePoint & OneDrive search/files/lists/excel, Teams chats/channels/messages, and Entra users/groups).
   - Automatically detects and removes any conflicting empty/generic data store with the same ID before provisioning.
   - Automatically binds the data store to your Gemini Enterprise Engine (`engine_id`), enabling the assistant to invoke the connector's tools.

## Prerequisites & Authentication

### 1. Google Cloud Authentication & Prerequisites

#### A. Authenticate
```bash
gcloud auth application-default login
gcloud config set project <YOUR_GCP_PROJECT_ID>
```

#### B. Discovery Engine Secret Access Prerequisite
The Discovery Engine service account (`service-<PROJECT_NUMBER>@gcp-sa-discoveryengine.iam.gserviceaccount.com`) requires the `roles/secretmanager.secretAccessor` role on the credentials secret so Discovery Engine can authenticate to Microsoft 365.

Because applying IAM policies to a secret requires `secretmanager.secrets.setIamPolicy`, you have two options:

- **Option 1 (Automatic via Terraform)**: Ensure the identity running Terraform has the **Secret Manager Admin** (`roles/secretmanager.admin`) role on the project. Terraform will then automatically apply the IAM binding during `terraform apply`.

- **Option 2 (Manual Grant by an Admin)**: If you do not have `roles/secretmanager.admin` (e.g., you only have secret/datastore creation permissions), get someone with that role to run:
  ```bash
  gcloud secrets add-iam-policy-binding ge-msft365-credentials \
    --member="serviceAccount:service-<PROJECT_NUMBER>@gcp-sa-discoveryengine.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor" \
    --project=<YOUR_GCP_PROJECT_ID>
  ```
  *(Note: If using Option 2, comment out the `google_secret_manager_secret_iam_member` resource in [`gcp_secrets.tf`](./gcp_secrets.tf) before running `terraform apply` so Terraform doesn't attempt `setIamPolicy` and encounter a 403 error).*




### 2. Microsoft Entra (Azure AD) Authentication
Terraform uses the Azure CLI to authenticate with your Microsoft Entra tenant.

#### A. Install Azure CLI
If you do not have Azure CLI installed, run:
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```

#### B. Authenticate
Sign in using device code:
```bash
az login --use-device-code --allow-no-subscriptions
```
*(If your account belongs to multiple tenants, add `--tenant <YOUR_TENANT_ID>`)*

---

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project_id and desired settings
terraform init
terraform apply
```

### Automated Provisioning & Verification

1. Run `terraform apply`. Terraform will:
   - Register the Entra application and generate client secrets with selected scopes.
   - Store credentials in Secret Manager and configure Discovery Engine service agent access.
   - Clean up any old empty/indeterminate data store with the configured ID.
   - Automatically call the Discovery Engine `setUpDataConnector` API to provision the unified Microsoft 365 connector (`dataSource: "msft"`).
2. If your Microsoft Entra tenant requires explicit admin consent for the configured scopes, visit the `microsoft_consent_verification_url` provided in the Terraform output. (Note: After clicking 'Accept', you can safely ignore any redirect error/warning such as "Couldn't connect your data source" or "Connecting your instance..."; Microsoft Entra records the granted consent before the redirect).
3. In Google Cloud Console, navigate to **[Gemini Enterprise Data Stores](https://console.cloud.google.com/gen-app-builder/data-stores)** to view your active Microsoft 365 data store.
4. In your Gemini Enterprise / Vertex AI Search App, go to **Configurations -> Tools / Extensions / Actions** to confirm that the Microsoft 365 tools (e.g. email, calendar, files, SharePoint search, Teams) are toggled ON for your Assistant.





