variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "europe-west2"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "demo-gke-cluster"
}

variable "node_count" {
  description = "Initial number of nodes per pool"
  type        = number
  default     = 3
}

variable "node_machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "node_disk_size_gb" {
  description = "Disk size in GB for each node in the pool"
  type        = number
  default     = 100
}

variable "node_disk_type" {
  description = "Disk type for the node pool (pd-standard or pd-ssd)"
  type        = string
  default     = "pd-standard"
}

variable "deletion_protection" {
  description = "Enable deletion protection for the GKE cluster (recommended true in production)"
  type        = bool
  default     = true
}

