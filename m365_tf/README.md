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

### 1. Google Cloud Authentication
Ensure you are authenticated with Google Cloud:
```bash
gcloud auth application-default login
gcloud config set project <YOUR_GCP_PROJECT_ID>
```

### 2. Microsoft Entra (Azure AD) Authentication
Terraform needs permission to register the Entra Application and Service Principal. Choose one of the following methods:

#### Method A: Azure CLI (Interactive)
Install the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) and sign in with an account that has `Application Developer` or `Global Administrator` role in your Entra tenant:
```bash
az login --tenant <YOUR_TENANT_ID>
```

#### Method B: Service Principal / Environment Variables (Headless / CI - No `az` CLI required)
If you don't have Azure CLI installed or are running in an automated pipeline, export the standard Azure credentials:
```bash
export ARM_TENANT_ID="<YOUR_TENANT_ID>"
export ARM_CLIENT_ID="<YOUR_SERVICE_PRINCIPAL_CLIENT_ID>"
export ARM_CLIENT_SECRET="<YOUR_SERVICE_PRINCIPAL_CLIENT_SECRET>"
```

Alternatively, you can provide `azure_tenant_id`, `azure_client_id`, and `azure_client_secret` directly in `terraform.tfvars`.

---

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project_id, azure_tenant_id, and desired permissions
terraform init
terraform apply
```

After `terraform apply`, open the generated `microsoft_consent_verification_url` in your browser to sign in and grant consent, or open the Cloud Console and click **Verify Auth**.

