resource "kubernetes_cluster_role" "kube_scan" {
  metadata {
    name = "kube-scan"
    labels = {
      app = "kube-scan"
    }
  }

  rule {
    api_groups = ["", "rbac.authorization.k8s.io", "extensions", "apps", "batch", "networking.k8s.io"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}