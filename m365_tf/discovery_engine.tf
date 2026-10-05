################################################################################
# Discovery Engine Data Store
################################################################################

resource "google_discovery_engine_data_store" "m365_datastore" {
  project           = var.project_id
  location          = var.location
  data_store_id     = var.data_store_id
  display_name      = var.data_store_display_name
  industry_vertical = "GENERIC"
  solution_types    = ["SOLUTION_TYPE_SEARCH"]
  content_config    = "CONTENT_REQUIRED"

  # Optional document processing or chunking can be added here if desired
}
