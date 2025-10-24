terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.26"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.26"
    }
  }
}

locals {
  node_pools_by_name = { for pool in var.node_pools : pool.name => pool }
}

resource "google_container_cluster" "this" {
  name     = var.name
  project  = var.project_id
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  workload_identity_config {
    workload_pool = var.workload_pool
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range
    services_secondary_range_name = var.services_secondary_range
  }

  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.enable_private_nodes ? coalesce(var.master_ipv4_cidr_block, "172.16.0.0/28") : null
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    dns_cache_config {
      enabled = true
    }

    gke_backup_agent_config {
      enabled = true
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []

    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks

        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = try(cidr_blocks.value.display_name, null)
        }
      }
    }
  }

  cluster_autoscaling {
    enabled = true

    dynamic "resource_limits" {
      for_each = var.cluster_resource_limits

      content {
        resource_type = resource_limits.value.resource_type
        minimum       = resource_limits.value.minimum
        maximum       = resource_limits.value.maximum
      }
    }
  }

  logging_config {
    enable_components = var.logging_components
  }

  monitoring_config {
    enable_components = var.monitoring_components
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  release_channel {
    channel = var.release_channel
  }

}

resource "google_container_node_pool" "this" {
  for_each = local.node_pools_by_name

  name              = each.value.name
  project           = var.project_id
  cluster           = google_container_cluster.this.name
  location          = var.location
  node_count        = each.value.min_count
  node_locations    = length(lookup(each.value, "locations", [])) > 0 ? lookup(each.value, "locations", []) : null
  max_pods_per_node = each.value.max_pods_per_node

  node_config {
    preemptible     = each.value.preemptible
    spot            = each.value.spot
    machine_type    = each.value.machine_type
    image_type      = each.value.image_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    service_account = each.value.service_account
    labels          = each.value.labels
    tags            = each.value.tags
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  autoscaling {
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }

  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

}
