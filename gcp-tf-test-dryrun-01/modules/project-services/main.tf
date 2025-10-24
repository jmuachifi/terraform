terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.26"
    }
  }
}

resource "google_project_service" "enabled" {
  for_each = toset(var.services)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = var.disable_on_destroy
}
