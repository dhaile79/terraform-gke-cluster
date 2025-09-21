variable "enabled" {
  type    = bool
  default = false
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "example" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "demo-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "demo-app"
    }

    min_replicas = 2
    max_replicas = 10

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}

