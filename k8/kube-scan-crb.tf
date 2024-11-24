resource "kubernetes_cluster_role_binding" "kube_scan" {
  metadata {
    name = "kube-scan"
    labels = {
      app = "kube-scan"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kube_scan.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.kube_scan.metadata[0].name
    namespace = kubernetes_namespace.kube_scan.metadata[0].name
  }
}