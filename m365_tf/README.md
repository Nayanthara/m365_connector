# Terraform Template for Microsoft 365 Connector (Google Cloud Discovery Engine)

This Terraform module automates the setup of the **Microsoft 365 Connector** for Google Cloud Discovery Engine (Vertex AI Search & Enterprise Search).

## What This Module Does

1. **Microsoft Entra (Azure AD) App Registration**:
   - Registers an OAuth 2.0 Web Application with redirect URI `https://vertexaisearch.cloud.google.com/console/oauth/default_oauth.html`.
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

4. **Google Cloud Infrastructure**:
   - Creates a Google Secret Manager secret containing the structured credentials payload (`tenant_id`, `client_id`, `client_secret`, `o365_environment_type`, `azure_host_url`).
   - Grants the Discovery Engine service agent (`service-<project-number>@gcp-sa-discoveryengine.iam.gserviceaccount.com`) Secret Accessor permissions.
   - Creates the Discovery Engine Data Store (`google_discovery_engine_data_store`) configured for Enterprise Search.

5. **Seamless Handoff Outputs**:
   - Outputs the generated client ID, client secret, and secret IDs.
   - Generates the exact `microsoft_consent_verification_url` so an administrator can grant consent with a single click.

## Prerequisites & Authentication

### 1. Google Cloud Authentication & Prerequisites

#### A. Authenticate
```bash
gcloud auth application-default login
gcloud config set project <YOUR_GCP_PROJECT_ID>
```

#### B. Minimum Required Roles & Permissions
The identity executing Terraform (your user account or CI/CD service account) requires the following minimum roles on the Google Cloud project:

| Role | Role Name | Purpose |
|------|-----------|---------|
| `roles/secretmanager.admin` | Secret Manager Admin | Manage the secret and set IAM policy (`secretmanager.secrets.setIamPolicy`) to grant read access to the Discovery Engine service agent. *(Note: `roles/secretmanager.secretAdmin` is insufficient as it cannot set IAM policies).* |
| `roles/discoveryengine.admin` | Discovery Engine Admin | Provision and configure the Discovery Engine data store. |
| `roles/browser` | Browser / Project Viewer | Read project metadata and project number. |

<details>
<summary><b>Granular Permissions</b> (for Custom IAM Roles)</summary>

- **Secret Manager**:
  - `secretmanager.secrets.create`
  - `secretmanager.secrets.get`
  - `secretmanager.secrets.update`
  - `secretmanager.secrets.delete`
  - `secretmanager.versions.add`
  - `secretmanager.versions.get`
  - `secretmanager.secrets.getIamPolicy`
  - `secretmanager.secrets.setIamPolicy`
- **Discovery Engine**:
  - `discoveryengine.dataStores.create`
  - `discoveryengine.dataStores.get`
  - `discoveryengine.dataStores.update`
  - `discoveryengine.dataStores.delete`
- **Resource Manager**:
  - `resourcemanager.projects.get`
</details>

#### C. Granting Permissions
A project administrator (with Owner or Project IAM Admin role) can run the following commands to grant the necessary permissions:

- **For a Service Account (e.g. CI/CD or Terraform runner)**:
  ```bash
  export PROJECT_ID="<YOUR_GCP_PROJECT_ID>"
  export SA_EMAIL="<SERVICE_ACCOUNT_EMAIL>"

  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/secretmanager.admin"

  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/discoveryengine.admin"
  ```

- **For a User Account**:
  ```bash
  export PROJECT_ID="<YOUR_GCP_PROJECT_ID>"
  export USER_EMAIL="<YOUR_EMAIL>"

  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:${USER_EMAIL}" \
    --role="roles/secretmanager.admin"

  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:${USER_EMAIL}" \
    --role="roles/discoveryengine.admin"
  ```



### 2. Microsoft Entra (Azure AD) Authentication
Terraform uses the Azure CLI to authenticate with your Microsoft Entra tenant.

#### A. Install Azure CLI
If you do not have Azure CLI installed:
- **Linux (Debian / Ubuntu / Cloudtop)**:
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```
- **macOS**:
  ```bash
  brew install azure-cli
  ```
- **Windows (PowerShell)**:
  ```powershell
  winget install Microsoft.AzureCLI
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

After `terraform apply`, open the generated `microsoft_consent_verification_url` in your browser to sign in and grant consent, or open the Cloud Console and click **Verify Auth**.



