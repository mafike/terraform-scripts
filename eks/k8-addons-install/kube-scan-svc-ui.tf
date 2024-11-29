resource "kubernetes_service" "kube_scan_ui" {
  metadata {
    name      = "kube-scan-ui"
    namespace = kubernetes_namespace.kube_scan.metadata[0].name
    labels = {
      app = "kube-scan"
    }
  }

  spec {
    selector = {
      app = "kube-scan"
    }

    port {
      name        = "kube-scan-ui"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}