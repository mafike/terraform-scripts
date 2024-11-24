
resource "kubectl_manifest" "peer_authentication" {
  yaml_body = <<YAML
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  namespace: istio-system
  name: mtls
spec:
  mtls:
    mode: STRICT
YAML
}