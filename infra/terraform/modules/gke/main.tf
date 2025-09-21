# Used to obtain an OAuth2 token for the active gcloud user
data "google_client_config" "default" {}

# ==========================================================
# Main GKE Cluster resource
# ==========================================================
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  # ==================================================================
  # Deletion protection is disabled here for TEST/DEMO purposes only.
  # In PROD ENV, always keep deletion_protection = true to prevent
  # accidental cluster deletion.
  # ==================================================================
  deletion_protection = var.deletion_protection

  # ----------------------------------------------------------
  # OPTION 1: AUTOPILOT MODE
  # Uncomment this block if you want GKE Autopilot.
  # GKE manages nodes fully (lifecycle, scaling, patching).
  # Billing is based on Pod requests, not VM instances.
  # ----------------------------------------------------------
  # autopilot {
  #   enabled = true
  # }

  # ----------------------------------------------------------
  # OPTION 2: USER-MANAGED NODES (DEFAULT)
  # This is the default path if the autopilot block is commented.
  # You manage node pools yourself (fine-grained control).
  # ----------------------------------------------------------
  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  release_channel {
    channel = "REGULAR"
  }

  # Workload Identity configuration
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# ==========================================================
# Example Node Pool (only relevant for USER-MANAGED clusters)
# If using Autopilot, comment this resource out.
# ==========================================================
resource "google_container_node_pool" "general" {
  name       = "${var.cluster_name}-general"
  location   = var.region
  project    = var.project_id
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    
    # Enable Workload Identity on node pool
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    labels = {
      role = "general"
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
}
