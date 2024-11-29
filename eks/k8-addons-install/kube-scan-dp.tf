resource "kubernetes_deployment" "kube_scan" {
  metadata {
    name      = "kube-scan"
    namespace = kubernetes_namespace.kube_scan.metadata[0].name
    labels = {
      app = "kube-scan"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "kube-scan"
      }
    }

    template {
      metadata {
        labels = {
          app = "kube-scan"
        }
      }

      spec {
        container {
          name  = "kube-scan-ui"
          image = "siddharth67/kubescan-scanner-ui"
          image_pull_policy = "Always"
          env {
            name  = "API_SERVER_PORT"
            value = "80"
          }
          env {
            name  = "CONTACT_LINK"
            value = "mailto:info@octarinesec.com?subject=Octarine%20Contact%20Request"
          }
          env {
            name  = "WEBSITE_LINK"
            value = "https://www.octarinesec.com"
          }
        }

        container {
          name  = "kube-scan"
          image = "siddharth67/kubescan-scanner"
          image_pull_policy = "Always"
          env {
            name  = "KUBESCAN_PORT"
            value = "80"
          }
          env {
            name  = "KUBESCAN_RISK_CONFIG_FILE_PATH"
            value = "/etc/kubescan/risk-config.yaml"
          }
          env {
            name  = "KUBESCAN_REFRESH_STATE_INTERVAL_MINUTES"
            value = "1440"
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/kubescan"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.kube_scan.metadata[0].name
          }
        }

        service_account_name = kubernetes_service_account.kube_scan.metadata[0].name
      }
    }
  }
}