# ==========================================================
# GKE Module Variables
# ==========================================================

variable "project_id" {
  description = "The GCP project ID where the GKE cluster will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for the GKE cluster (e.g., europe-west2)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool (only for user-managed mode)"
  type        = number
  default     = 3
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes (only for user-managed mode)"
  type        = string
  default     = "e2-medium"
}


variable "node_disk_size_gb" {
  description = "Size of the boot disk for each node in GB"
  type        = number
  default     = 30  # Safe for test projects
}

variable "node_disk_type" {
  description = "Type of disk to use for nodes (pd-standard or pd-ssd)"
  type        = string
  default     = "pd-standard"
}



variable "deletion_protection" {
  description = "Enable deletion protection for the GKE cluster (recommended true in production)"
  type        = bool
  default     = true
}

