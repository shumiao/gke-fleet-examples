# This configuration enables configmanagement feature by default.
# and then creates 2 team scopes and 3 clusters, and bind them according
# to the diagram in README.

locals {
  fleet_project = "shumiao-test"
}

provider "google" {
  project = "shumiao-test"
  region  = "us-central1" # Example region; adjust accordingly
}

locals {
  // there is a bug in process to make this simpler, but for now use
  // this regex on the membership resource to extract what we need:
  //
  // fleet host project is match #0
  // location is match #1
  // membership is match #2
  membership_re = "//gkehub.googleapis.com/projects/([^/]*)/locations/([^/]*)/memberships/([^/]*)$"
}

# Provision config management feature in the fleet host project.
resource "google_gke_hub_feature" "configmanagement_feature" {
  name     = "configmanagement"
  location = "global"
  project  = local.fleet_project
  fleet_default_member_config {
    configmanagement {
      config_sync {
        source_format = "unstructured"
        git {
          sync_repo   = "https://github.com/shumiao/gke-fleet-examples/tree/main/config-management/"
          sync_branch = "main"
          policy_dir  = "configs"
          secret_type = "none"
        }
      }
    }
  }
}

# Provision teams' scopes with namespaces. 
resource "google_gke_hub_scope" "scopes" {
  for_each = {
    "backend"  = {}
    "frontend" = {}
  }
  project  = local.fleet_project
  scope_id = each.key
}

resource "google_gke_hub_namespace" "frontend_team_namespaces" {
  for_each           = toset(["frontent-a", "frontent-b"])
  project            = local.fleet_project
  scope_namespace_id = "${each.key}"
  scope_id           = "frontend"
  scope              = google_gke_hub_scope.scopes["frontend"].id
}
resource "google_gke_hub_namespace" "backend_team_namespaces" {
  for_each           = toset(["bookstore", "shoestore"])
  project            = local.fleet_project
  scope_namespace_id = "${each.key}"
  scope_id           = "backend"
  scope              = google_gke_hub_scope.scopes["backend"].id
}

# Provision 3 clusters, and bind them to the teams' scopes.
resource "google_container_cluster" "clusters" {
  count = 3
  name  = "tf-cluster-${count.index}"
  initial_node_count = 3
  fleet {
    project = local.fleet_project
  }
  deletion_protection = false
  # create feature before clusters to ensure the fleet_default_member_config
  # is applied to the clusters.
  depends_on = [google_gke_hub_feature.configmanagement_feature]
}
# bind cluster 1 & 2 to backend scope
resource "google_gke_hub_membership_binding" "backend_cluster_bindings" {
  count                 = 2
  project               = local.fleet_project
  membership_binding_id = "to-backend"
  scope                 = "backend"
  membership_id         = regex(local.membership_re, google_container_cluster.clusters[count.index].fleet[0].membership)[2]
  location              = regex(local.membership_re, google_container_cluster.clusters[count.index].fleet[0].membership)[1]
}
# bind all 3 clusters to frontend scope
resource "google_gke_hub_membership_binding" "frontend_cluster_bindings" {
  count                 = 3
  project               = local.fleet_project
  membership_binding_id = "to-frontend"
  scope                 = "frontend"
  membership_id         = regex(local.membership_re, google_container_cluster.clusters[count.index].fleet[0].membership)[2]
  location              = regex(local.membership_re, google_container_cluster.clusters[count.index].fleet[0].membership)[1]
}
