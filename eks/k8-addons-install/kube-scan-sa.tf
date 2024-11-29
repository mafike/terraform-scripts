resource "kubernetes_service_account" "kube_scan" {
  metadata {
    name      = "kube-scan"
    namespace = kubernetes_namespace.kube_scan.metadata[0].name
    labels = {
      app = "kube-scan"
    }
  }
}