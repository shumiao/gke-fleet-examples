locals {
  fleet_project = "shumiao-test"
  membership_re = "//gkehub.googleapis.com/projects/([^/]*)/locations/([^/]*)/memberships/([^/]*)$"
}

provider "google" {
  project = "shumiao-test"
  region  = "us-central1"
}

# Provision 3 application clusters
resource "google_container_cluster" "clusters" {
  count = 3
  name  = "app-cluster-${count.index}"
  initial_node_count = 3
  fleet {
    project = local.fleet_project
  }
  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${fleet_project}.svc.id.goog"
  }
  deletion_protection = false
}

# Provision two teams "backend" and "frontend"
resource "google_gke_hub_scope" "scopes" {
  for_each = {
    "backend"  = {}
    "frontend" = {}
  }
  project  = local.fleet_project
  scope_id = each.key
}

resource "google_gke_hub_namespace" "frontend_team_namespaces" {
  project            = local.fleet_project
  scope_namespace_id = "webserver"
  scope_id           = "frontend"
  scope              = google_gke_hub_scope.scopes["frontend"].id
}

# Bind cluster 1 & 2 to the "frontend" scope
resource "google_gke_hub_membership_binding" "backend_cluster_bindings" {
  count                 = 2
  project               = local.fleet_project
  membership_binding_id = "to-frontend"
  scope                 = google_gke_hub_scope.scopes["frontend"].id
  membership_id         = regex(local.membership_re, google_container_cluster.clusters[count.index].fleet[0].membership)[2]
  location              = regex(local.membership_re, google_container_cluster.clusters[count.index].fleet[0].membership)[1]
}
