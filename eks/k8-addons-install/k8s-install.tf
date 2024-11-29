resource "null_resource" "install_helm" {
  provisioner "local-exec" {
    command = <<EOT
    curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-v3.16.3-darwin-arm64.tar.gz
    tar -zxvf helm.tar.gz
    mv darwin-arm64/helm ~/bin/helm
    echo "Helm installed in ~/bin/helm"
    export PATH=$PATH:~/bin
  EOT
}
  triggers = {
    always_run = timestamp() # Ensures the provisioner always runs
  }
}

resource "helm_release" "falco" {
  depends_on = [null_resource.install_helm,kubernetes_namespace.falco]

  name       = "falco"
  namespace  = "falco"
  chart      = "falco"
  repository = "https://falcosecurity.github.io/charts"

  values = [file("./falco-values.yaml")]
}

resource "helm_release" "vault" {
  depends_on = [null_resource.install_helm, kubernetes_namespace.vault]

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
  depends_on = [null_resource.install_helm, kubernetes_namespace.monitoring]

  name       = "alertmanager"
  namespace  = "monitoring"
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"

  values = [file("./alermanager.yml")]
}

resource "kubernetes_namespace" "falco" {
  metadata {
    name = "falco"
  }
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "istio-system" {
  metadata {
    name = "istio-system"
  }
}