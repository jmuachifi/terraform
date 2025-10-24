terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.26"
    }
  }
}

resource "google_compute_network" "this" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

locals {
  subnet_configs = {
    for subnet in var.subnets : subnet.name => subnet
  }
}

resource "google_compute_subnetwork" "this" {
  for_each = local.subnet_configs

  name                     = each.value.name
  project                  = var.project_id
  region                   = each.value.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = each.value.ip_cidr_range
  private_ip_google_access = each.value.private_ip_google_access
  purpose                  = try(each.value.purpose, null)
  role                     = try(each.value.role, null)

  dynamic "secondary_ip_range" {
    for_each = try(each.value.secondary_ip_ranges, [])

    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

resource "google_compute_router" "this" {
  count   = var.create_nat ? 1 : 0
  name    = var.router_name
  project = var.project_id
  region  = one(distinct([for s in var.subnets : s.region]))
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  count   = var.create_nat ? 1 : 0
  name    = var.nat_name
  project = var.project_id
  region  = google_compute_router.this[0].region
  router  = google_compute_router.this[0].name

  nat_ips                            = []
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.this

    content {
      name                    = subnetwork.value.name
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
