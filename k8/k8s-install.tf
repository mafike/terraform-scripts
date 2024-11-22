/* resource "null_resource" "install_helm" {
  provisioner "local-exec" {
    command = <<EOT
      export VERIFY_CHECKSUM=false
      curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
    EOT
  }
}

resource "helm_release" "falco" {
  depends_on = [null_resource.install_helm]

  name       = "falco"
  namespace  = "falco"
  chart      = "falco"
  repository = "https://falcosecurity.github.io/charts"

  values = [file("values/falco-values.yaml")]
}

resource "helm_release" "vault" {
  depends_on = [null_resource.install_helm]

  name       = "vault"
  namespace  = "vault"
  chart      = "vault"
  repository = "https://helm.releases.hashicorp.com"

  values = [<<EOF
ui:
  enabled: false
server:
  dataStorage:
    enabled: false
EOF
  ]
}

resource "helm_release" "alertmanager" {
  depends_on = [null_resource.install_helm]

  name       = "alertmanager"
  namespace  = "monitoring"
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"

  values = [file("values/alermanager.yml")]
}
*/
