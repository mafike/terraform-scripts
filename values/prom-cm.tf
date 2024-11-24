resource "kubectl_manifest" "prometheus-cm" {
    yaml_body = <<YAML
apiVersion: v1
data:
  alerting_rules.yml: |
    {
       "groups": [
         {
           "name": "Rules",
           "rules": [
             {
               "alert": "InstanceDown",
               "expr": "up == 0",
               "for": "0m",
               "annotations": {
                 "title": "Instance {{ $labels.instance }} down",
                 "description": "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute."
               },
               "labels": {
                 "severity": "critical"
               }
             },
             {
               "alert": "KubernetesPodClientError",
               "expr": "istio_requests_total{reporter=\"destination\", response_code=\"403\"} > 10",
               "labels": {
                 "severity": "warning"
               },
               "annotations": {
                 "summary": "Kubernetes pod Client Error (instance {{ $labels.instance }})",
                 "description": "Pod {{ $labels.instance }} of job {{ $labels.job }} reported client specific issues"
               }
             }
           ]
         }
       ]
     }
  alerts: |
    {}
  allow-snippet-annotations: "false"
  prometheus.yml: |
    global:
      evaluation_interval: 1m
      scrape_interval: 15s
      scrape_timeout: 10s
    alerting:
      alertmanagers:
      - static_configs:
      - targets:
         - http://192.168.33.11:9093
    rule_files:
    - /etc/config/recording_rules.yml
    - /etc/config/alerting_rules.yml
    - /etc/config/rules
    - /etc/config/alerts
    scrape_configs:
    - job_name: prometheus
      static_configs:
      - targets:
        - localhost:9090
    - bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      job_name: kubernetes-apiservers
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - action: keep
        regex: default;kubernetes;https
        source_labels:
        - __meta_kubernetes_namespace
        - __meta_kubernetes_service_name
        - __meta_kubernetes_endpoint_port_name
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
    - bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      job_name: kubernetes-nodes
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - replacement: kubernetes.default.svc:443
        target_label: __address__
      - regex: (.+)
        replacement: /api/v1/nodes/$1/proxy/metrics
        source_labels:
        - __meta_kubernetes_node_name
        target_label: __metrics_path__
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
    - bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      job_name: kubernetes-nodes-cadvisor
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - replacement: kubernetes.default.svc:443
        target_label: __address__
      - regex: (.+)
        replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor
        source_labels:
        - __meta_kubernetes_node_name
        target_label: __metrics_path__
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
    - honor_labels: true
      job_name: kubernetes-service-endpoints
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scrape
      - action: drop
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scrape_slow
      - action: replace
        regex: (https?)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scheme
        target_label: __scheme__
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_path
        target_label: __metrics_path__
      - action: replace
        regex: (.+?)(?::\d+)?;(\d+)
        replacement: $1:$2
        source_labels:
        - __address__
        - __meta_kubernetes_service_annotation_prometheus_io_port
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_annotation_prometheus_io_param_(.+)
        replacement: __param_$1
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_service_name
        target_label: service
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: node
    - honor_labels: true
      job_name: kubernetes-service-endpoints-slow
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scrape_slow
      - action: replace
        regex: (https?)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scheme
        target_label: __scheme__
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_path
        target_label: __metrics_path__
      - action: replace
        regex: (.+?)(?::\d+)?;(\d+)
        replacement: $1:$2
        source_labels:
        - __address__
        - __meta_kubernetes_service_annotation_prometheus_io_port
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_annotation_prometheus_io_param_(.+)
        replacement: __param_$1
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_service_name
        target_label: service
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: node
      scrape_interval: 5m
      scrape_timeout: 30s
    - honor_labels: true
      job_name: prometheus-pushgateway
      kubernetes_sd_configs:
      - role: service
      relabel_configs:
      - action: keep
        regex: pushgateway
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_probe
    - honor_labels: true
      job_name: kubernetes-services
      kubernetes_sd_configs:
      - role: service
      metrics_path: /probe
      params:
        module:
        - http_2xx
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_probe
      - source_labels:
        - __address__
        target_label: __param_target
      - replacement: blackbox
        target_label: __address__
      - source_labels:
        - __param_target
        target_label: instance
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - source_labels:
        - __meta_kubernetes_service_name
        target_label: service
    - honor_labels: true
      job_name: kubernetes-pods
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_scrape
      - action: drop
        regex: true
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_scrape_slow
      - action: replace
        regex: (https?)
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_scheme
        target_label: __scheme__
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_path
        target_label: __metrics_path__
      - action: replace
        regex: (\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})
        replacement: '[$2]:$1'
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_port
        - __meta_kubernetes_pod_ip
        target_label: __address__
      - action: replace
        regex: (\d+);((([0-9]+?)(\.|$)){4})
        replacement: $2:$1
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_port
        - __meta_kubernetes_pod_ip
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_annotation_prometheus_io_param_(.+)
        replacement: __param_$1
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - action: drop
        regex: Pending|Succeeded|Failed|Completed
        source_labels:
        - __meta_kubernetes_pod_phase
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: node
    - honor_labels: true
      job_name: kubernetes-pods-slow
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_scrape_slow
      - action: replace
        regex: (https?)
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_scheme
        target_label: __scheme__
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_path
        target_label: __metrics_path__
      - action: replace
        regex: (\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})
        replacement: '[$2]:$1'
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_port
        - __meta_kubernetes_pod_ip
        target_label: __address__
      - action: replace
        regex: (\d+);((([0-9]+?)(\.|$)){4})
        replacement: $2:$1
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_port
        - __meta_kubernetes_pod_ip
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_annotation_prometheus_io_param_(.+)
        replacement: __param_$1
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - action: drop
        regex: Pending|Succeeded|Failed|Completed
        source_labels:
        - __meta_kubernetes_pod_phase
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: node
      scrape_interval: 5m
      scrape_timeout: 30s
  recording_rules.yml: |
    {}
  rules: |
    {}
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"alerting_rules.yml":"{\n   \"groups\": [\n     {\n       \"name\": \"Rules\",\n       \"rules\": [\n         {\n           \"alert\": \"Insta
nceDown\",\n           \"expr\": \"up == 0\",\n           \"for\": \"0m\",\n           \"annotations\": {\n             \"title\": \"Instance {{ $labels.instance }} down\",\n
            \"description\": \"{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute.\"\n           },\n           \"labels\": {\n             \
"severity\": \"critical\"\n           }\n         },\n         {\n           \"alert\": \"KubernetesPodClientError\",\n           \"expr\": \"istio_requests_total{reporter=\\\
"destination\\\", response_code=\\\"403\\\"} \u003e 10\",\n           \"labels\": {\n             \"severity\": \"warning\"\n           },\n           \"annotations\": {\n
         \"summary\": \"Kubernetes pod Client Error (instance {{ $labels.instance }})\",\n             \"description\": \"Pod {{ $labels.instance }} of job {{ $labels.job }} r
eported client specific issues\"\n           }\n         }\n       ]\n     }\n   ]\n }\n","alerts":"{}\n","allow-snippet-annotations":"false","prometheus.yml":"global:\n  eval
uation_interval: 1m\n  scrape_interval: 15s\n  scrape_timeout: 10s\nalerting:\n  alertmanagers:\n  - static_configs:\n  - targets:\n     - http://192.168.33.11:9093\nrule_file
s:\n- /etc/config/recording_rules.yml\n- /etc/config/alerting_rules.yml\n- /etc/config/rules\n- /etc/config/alerts\nscrape_configs:\n- job_name: prometheus\n  static_configs:\
n  - targets:\n    - localhost:9090\n- bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n  job_name: kubernetes-apiservers\n  kubernetes_sd_configs:\n  -
 role: endpoints\n  relabel_configs:\n  - action: keep\n    regex: default;kubernetes;https\n    source_labels:\n    - __meta_kubernetes_namespace\n    - __meta_kubernetes_ser
vice_name\n    - __meta_kubernetes_endpoint_port_name\n  scheme: https\n  tls_config:\n    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n    insecure_skip_ver
ify: true\n- bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n  job_name: kubernetes-nodes\n  kubernetes_sd_configs:\n  - role: node\n  relabel_configs:
\n  - action: labelmap\n    regex: __meta_kubernetes_node_label_(.+)\n  - replacement: kubernetes.default.svc:443\n    target_label: __address__\n  - regex: (.+)\n    replacem
ent: /api/v1/nodes/$1/proxy/metrics\n    source_labels:\n    - __meta_kubernetes_node_name\n    target_label: __metrics_path__\n  scheme: https\n  tls_config:\n    ca_file: /v
ar/run/secrets/kubernetes.io/serviceaccount/ca.crt\n    insecure_skip_verify: true\n- bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n  job_name: kuber
netes-nodes-cadvisor\n  kubernetes_sd_configs:\n  - role: node\n  relabel_configs:\n  - action: labelmap\n    regex: __meta_kubernetes_node_label_(.+)\n  - replacement: kubern
etes.default.svc:443\n    target_label: __address__\n  - regex: (.+)\n    replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor\n    source_labels:\n    - __meta_kubernetes_nod
e_name\n    target_label: __metrics_path__\n  scheme: https\n  tls_config:\n    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n    insecure_skip_verify: true\n
- honor_labels: true\n  job_name: kubernetes-service-endpoints\n  kubernetes_sd_configs:\n  - role: endpoints\n  relabel_configs:\n  - action: keep\n    regex: true\n    sourc
e_labels:\n    - __meta_kubernetes_service_annotation_prometheus_io_scrape\n  - action: drop\n    regex: true\n    source_labels:\n    - __meta_kubernetes_service_annotation_p
rometheus_io_scrape_slow\n  - action: replace\n    regex: (https?)\n    source_labels:\n    - __meta_kubernetes_service_annotation_prometheus_io_scheme\n    target_label: __sc
heme__\n  - action: replace\n    regex: (.+)\n    source_labels:\n    - __meta_kubernetes_service_annotation_prometheus_io_path\n    target_label: __metrics_path__\n  - action
: replace\n    regex: (.+?)(?::\\d+)?;(\\d+)\n    replacement: $1:$2\n    source_labels:\n    - __address__\n    - __meta_kubernetes_service_annotation_prometheus_io_port\n
 target_label: __address__\n  - action: labelmap\n    regex: __meta_kubernetes_service_annotation_prometheus_io_param_(.+)\n    replacement: __param_$1\n  - action: labelmap\n
    regex: __meta_kubernetes_service_label_(.+)\n  - action: replace\n    source_labels:\n    - __meta_kubernetes_namespace\n    target_label: namespace\n  - action: replace\n
    source_labels:\n    - __meta_kubernetes_service_name\n    target_label: service\n  - action: replace\n    source_labels:\n    - __meta_kubernetes_pod_node_name\n    target
_label: node\n- honor_labels: true\n  job_name: kubernetes-service-endpoints-slow\n  kubernetes_sd_configs:\n  - role: endpoints\n  relabel_configs:\n  - action: keep\n    reg
ex: true\n    source_labels:\n    - __meta_kubernetes_service_annotation_prometheus_io_scrape_slow\n  - action: replace\n    regex: (https?)\n    source_labels:\n    - __meta_
kubernetes_service_annotation_prometheus_io_scheme\n    target_label: __scheme__\n  - action: replace\n    regex: (.+)\n    source_labels:\n    - __meta_kubernetes_service_ann
otation_prometheus_io_path\n    target_label: __metrics_path__\n  - action: replace\n    regex: (.+?)(?::\\d+)?;(\\d+)\n    replacement: $1:$2\n    source_labels:\n    - __add
ress__\n    - __meta_kubernetes_service_annotation_prometheus_io_port\n    target_label: __address__\n  - action: labelmap\n    regex: __meta_kubernetes_service_annotation_pro
metheus_io_param_(.+)\n    replacement: __param_$1\n  - action: labelmap\n    regex: __meta_kubernetes_service_label_(.+)\n  - action: replace\n    source_labels:\n    - __met
a_kubernetes_namespace\n    target_label: namespace\n  - action: replace\n    source_labels:\n    - __meta_kubernetes_service_name\n    target_label: service\n  - action: repl
ace\n    source_labels:\n    - __meta_kubernetes_pod_node_name\n    target_label: node\n  scrape_interval: 5m\n  scrape_timeout: 30s\n- honor_labels: true\n  job_name: prometh
eus-pushgateway\n  kubernetes_sd_configs:\n  - role: service\n  relabel_configs:\n  - action: keep\n    regex: pushgateway\n    source_labels:\n    - __meta_kubernetes_service
_annotation_prometheus_io_probe\n- honor_labels: true\n  job_name: kubernetes-services\n  kubernetes_sd_configs:\n  - role: service\n  metrics_path: /probe\n  params:\n    mod
ule:\n    - http_2xx\n  relabel_configs:\n  - action: keep\n    regex: true\n    source_labels:\n    - __meta_kubernetes_service_annotation_prometheus_io_probe\n  - source_lab
els:\n    - __address__\n    target_label: __param_target\n  - replacement: blackbox\n    target_label: __address__\n  - source_labels:\n    - __param_target\n    target_label
: instance\n  - action: labelmap\n    regex: __meta_kubernetes_service_label_(.+)\n  - source_labels:\n    - __meta_kubernetes_namespace\n    target_label: namespace\n  - sour
ce_labels:\n    - __meta_kubernetes_service_name\n    target_label: service\n- honor_labels: true\n  job_name: kubernetes-pods\n  kubernetes_sd_configs:\n  - role: pod\n  rela
bel_configs:\n  - action: keep\n    regex: true\n    source_labels:\n    - __meta_kubernetes_pod_annotation_prometheus_io_scrape\n  - action: drop\n    regex: true\n    source
_labels:\n    - __meta_kubernetes_pod_annotation_prometheus_io_scrape_slow\n  - action: replace\n    regex: (https?)\n    source_labels:\n    - __meta_kubernetes_pod_annotatio
n_prometheus_io_scheme\n    target_label: __scheme__\n  - action: replace\n    regex: (.+)\n    source_labels:\n    - __meta_kubernetes_pod_annotation_prometheus_io_path\n
target_label: __metrics_path__\n  - action: replace\n    regex: (\\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})\n    replacement: '[$2]:$1'\n    source_labels:\n    - __me
ta_kubernetes_pod_annotation_prometheus_io_port\n    - __meta_kubernetes_pod_ip\n    target_label: __address__\n  - action: replace\n    regex: (\\d+);((([0-9]+?)(\\.|$)){4})\
n    replacement: $2:$1\n    source_labels:\n    - __meta_kubernetes_pod_annotation_prometheus_io_port\n    - __meta_kubernetes_pod_ip\n    target_label: __address__\n  - acti
on: labelmap\n    regex: __meta_kubernetes_pod_annotation_prometheus_io_param_(.+)\n    replacement: __param_$1\n  - action: labelmap\n    regex: __meta_kubernetes_pod_label_(
.+)\n  - action: replace\n    source_labels:\n    - __meta_kubernetes_namespace\n    target_label: namespace\n  - action: replace\n    source_labels:\n    - __meta_kubernetes_
pod_name\n    target_label: pod\n  - action: drop\n    regex: Pending|Succeeded|Failed|Completed\n    source_labels:\n    - __meta_kubernetes_pod_phase\n  - action: replace\n
   source_labels:\n    - __meta_kubernetes_pod_node_name\n    target_label: node\n- honor_labels: true\n  job_name: kubernetes-pods-slow\n  kubernetes_sd_configs:\n  - role: p
od\n  relabel_configs:\n  - action: keep\n    regex: true\n    source_labels:\n    - __meta_kubernetes_pod_annotation_prometheus_io_scrape_slow\n  - action: replace\n    regex
: (https?)\n    source_labels:\n    - __meta_kubernetes_pod_annotation_prometheus_io_scheme\n    target_label: __scheme__\n  - action: replace\n    regex: (.+)\n    source_lab
els:\n    - __meta_kubernetes_pod_annotation_prometheus_io_path\n    target_label: __metrics_path__\n  - action: replace\n    regex: (\\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0
-9]{1,4})\n    replacement: '[$2]:$1'\n    source_labels:\n    - __meta_kubernetes_pod_annotation_prometheus_io_port\n    - __meta_kubernetes_pod_ip\n    target_label: __addre
ss__\n  - action: replace\n    regex: (\\d+);((([0-9]+?)(\\.|$)){4})\n    replacement: $2:$1\n    source_labels:\n    - __meta_kubernetes_pod_annotation_prometheus_io_port\n
  - __meta_kubernetes_pod_ip\n    target_label: __address__\n  - action: labelmap\n    regex: __meta_kubernetes_pod_annotation_prometheus_io_param_(.+)\n    replacement: __par
am_$1\n  - action: labelmap\n    regex: __meta_kubernetes_pod_label_(.+)\n  - action: replace\n    source_labels:\n    - __meta_kubernetes_namespace\n    target_label: namespa
ce\n  - action: replace\n    source_labels:\n    - __meta_kubernetes_pod_name\n    target_label: pod\n  - action: drop\n    regex: Pending|Succeeded|Failed|Completed\n    sour
ce_labels:\n    - __meta_kubernetes_pod_phase\n  - action: replace\n    source_labels:\n    - __meta_kubernetes_pod_node_name\n    target_label: node\n  scrape_interval: 5m\n
 scrape_timeout: 30s\n","recording_rules.yml":"{}\n","rules":"{}\n"},"kind":"ConfigMap","metadata":{"annotations":{},"creationTimestamp":"2024-11-16T00:30:41Z","labels":{"app.
kubernetes.io/component":"server","app.kubernetes.io/instance":"prometheus","app.kubernetes.io/managed-by":"Helm","app.kubernetes.io/name":"prometheus","app.kubernetes.io/part
-of":"prometheus","app.kubernetes.io/version":"v2.54.1","helm.sh/chart":"prometheus-25.27.0"},"name":"prometheus","namespace":"istio-system","resourceVersion":"141972","uid":"
f9b7100e-6e14-4f8c-b62c-ebf43c8ff347"}}
  creationTimestamp: "2024-11-16T00:30:41Z"
  labels:
    app.kubernetes.io/component: server
    app.kubernetes.io/instance: prometheus
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/part-of: prometheus
    app.kubernetes.io/version: v2.54.1
    helm.sh/chart: prometheus-25.27.0
  name: prometheus
  namespace: istio-system
  resourceVersion: "143540"
  uid: f9b7100e-6e14-4f8c-b62c-ebf43c8ff347
  YAML
}
