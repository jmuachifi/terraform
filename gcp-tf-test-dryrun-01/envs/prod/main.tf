locals {
  workload_identity_pool = var.workload_identity_pool != "" ? var.workload_identity_pool : "${var.project_id}.svc.id.goog"
}

module "project_services" {
  source     = "../../modules/project-services"
  project_id = var.project_id
}

module "network" {
  source       = "../../modules/network"
  project_id   = var.project_id
  network_name = var.network_name

  subnets = [
    for subnet in var.subnets : {
      name                     = subnet.name
      ip_cidr_range            = subnet.ip_cidr_range
      region                   = subnet.region
      secondary_ip_ranges      = subnet.secondary_ip_ranges
      private_ip_google_access = true
    }
  ]
}

resource "google_service_account" "gke_nodes" {
  account_id   = "gke-prod-nodes"
  display_name = "GKE Prod Node Pool"
}

resource "google_project_iam_member" "gke_node_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/compute.networkUser"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

locals {
  computed_node_pools = length(var.node_pools) > 0 ? [
    for pool in var.node_pools : merge(pool, {
      service_account = pool.service_account != "" ? pool.service_account : google_service_account.gke_nodes.email,
      labels          = merge({ env = "prod" }, try(pool.labels, {}))
    })
    ] : [
    {
      name            = "prod-primary"
      machine_type    = "n2-standard-8"
      min_count       = 3
      max_count       = 6
      disk_size_gb    = 150
      service_account = google_service_account.gke_nodes.email
      labels = {
        env      = "prod"
        workload = "general"
      }
      tags = ["prod", "gke"]
    },
    {
      name            = "prod-spot"
      machine_type    = "e2-standard-8"
      min_count       = 0
      max_count       = 4
      spot            = true
      service_account = google_service_account.gke_nodes.email
      labels = {
        env      = "prod"
        workload = "batch"
      }
      tags = ["prod", "gke", "spot"]
    }
  ]
}

module "gke_cluster" {
  source     = "../../modules/gke-cluster"
  project_id = var.project_id
  name       = "prod-gke"
  location   = var.cluster_location
  network    = module.network.network_self_link
  subnetwork = module.network.subnet_self_links[var.subnets[0].name]

  pods_secondary_range       = var.pods_secondary_range_name
  services_secondary_range   = var.services_secondary_range_name
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  release_channel            = var.release_channel
  workload_pool              = local.workload_identity_pool
  master_authorized_networks = var.master_authorized_networks
  node_pools                 = local.computed_node_pools
  enable_private_nodes       = var.enable_private_nodes
  enable_private_endpoint    = var.enable_private_endpoint
  logging_components         = var.logging_components
  monitoring_components      = var.monitoring_components
}

output "gke_cluster_name" {
  value       = module.gke_cluster.cluster_name
  description = "Cluster name for production environment."
}

output "network_self_link" {
  description = "VPC self link created for the environment."
  value       = module.network.network_self_link
}
