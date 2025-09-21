terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"   
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Wire the kubernetes provider to the cluster built by the gke module
provider "kubernetes" {
  alias                  = "gke"
  host                   = module.gke.kubeconfig.host
  token                  = module.gke.kubeconfig.token
  cluster_ca_certificate = base64decode(module.gke.kubeconfig.cluster_ca_certificate)
}

