variable "enabled" { default = false }

resource "kubernetes_manifest" "vpa" {
  count = var.enabled ? 1 : 0
  manifest = {
    apiVersion = "autoscaling.k8s.io/v1"
    kind       = "VerticalPodAutoscaler"
    metadata = {
      name      = "demo-vpa"
      namespace = "default"
    }
    spec = {
      targetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = "demo-app"
      }
      updatePolicy = {
        updateMode = "Auto"
      }
    }
  }
}

