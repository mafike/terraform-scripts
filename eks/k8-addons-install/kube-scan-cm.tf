resource "kubernetes_config_map" "kube_scan" {
  metadata {
    name      = "kube-scan"
    namespace = kubernetes_namespace.kube_scan.metadata[0].name
    labels = {
      app = "kube-scan"
    }
  }

  data = {
    "risk-config.yaml" = <<EOT
expConst: 9
impactConst: 4
attackVector:
  remote: 0.85
  local: 0.55
...
EOT
  }
}