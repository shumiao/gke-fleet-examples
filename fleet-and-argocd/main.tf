locals {
  fleet_project = "shumiao-test"
}

# Provision a control cluster in the fleet. It is used as the Management Cluster of Argo CD.
resource "google_container_cluster" "fleet-control-cluster" {
  name  = "fleet-control-cluster"
  initial_node_count = 3
  fleet {
    project = local.fleet_project
  }
  deletion_protection = false
}