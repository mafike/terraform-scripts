resource "kubernetes_namespace" "kube_scan" {
  metadata {
    name = "kube-scan"
  }
}