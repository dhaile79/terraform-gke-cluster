output "cluster_name" {
  value = module.gke.cluster_name
}

output "kubeconfig" {
  value = module.gke.kubeconfig
  sensitive = true
}

