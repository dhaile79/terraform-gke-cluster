##########################################
# GKE Cluster Module
##########################################

module "gke" {
  source = "./modules/gke"

  project_id        = var.project_id
  region            = var.region
  cluster_name      = var.cluster_name
  node_count        = var.node_count
  node_machine_type = var.node_machine_type
  deletion_protection = var.deletion_protection
}

##########################################
# Horizontal Pod Autoscaler (HPA)
##########################################

module "hpa" {
  source  = "./modules/hpa"
  enabled = true
  providers  = { kubernetes = kubernetes.gke }  # << use aliased provider
  depends_on = [module.gke]                      # << ensure cluster exists first
}

##########################################
# Vertical Pod Autoscaler (VPA)
##########################################

module "vpa" {
  source  = "./modules/vpa"
  enabled = false
  providers  = { kubernetes = kubernetes.gke }
  depends_on = [module.gke]
}

