# Expose a kubeconfig-like map so the root can wire the Kubernetes provider.

output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "location" {
  value = google_container_cluster.primary.location
}


output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}


# Kube API endpoint + CA cert + an access token the provider can use
output "kubeconfig" {
  value = {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    cluster_ca_certificate = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
    # token comes from calling Google API; we read it via data.google_client_config.default.access_token
    token                  = data.google_client_config.default.access_token
  }
  sensitive = true
}

