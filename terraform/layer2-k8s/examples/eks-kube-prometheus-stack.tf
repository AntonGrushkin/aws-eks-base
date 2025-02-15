locals {
  grafana_password         = random_string.grafana_password.result
  grafana_domain_name      = "grafana.${local.domain_name}"
  prometheus_domain_name   = "prometheus.${local.domain_name}"
  alertmanager_domain_name = "alertmanager.${local.domain_name}"

  kube_prometheus_stack_template = templatefile("${path.module}/templates/prometheus-values.tmpl",
    {
      prometheus_domain_name               = local.prometheus_domain_name
      alertmanager_domain_name             = local.alertmanager_domain_name
      ip_whitelist                         = local.ip_whitelist
      default_region                       = local.region
      grafana_domain_name                  = local.grafana_domain_name
      grafana_password                     = local.grafana_password
      role_arn                             = module.aws_iam_grafana.role_arn
      gitlab_client_id                     = local.grafana_gitlab_client_id
      gitlab_client_secret                 = local.grafana_gitlab_client_secret
      alertmanager_slack_url               = local.alertmanager_slack_url
      alertmanager_slack_channel           = var.alertmanager_slack_channel
      loki_datasource_for_prometheus_stack = var.loki_datasource_for_prometheus_stack
  })
}

resource "random_string" "grafana_password" {
  length  = 20
  special = true
}

module "aws_iam_grafana" {
  source = "../modules/aws-iam-grafana"

  name              = local.name
  region            = local.region
  oidc_provider_arn = local.eks_oidc_provider_arn
}

resource "helm_release" "prometheus_operator" {
  name       = "kube-prometheus-stack"
  chart      = "kube-prometheus-stack"
  repository = local.helm_repo_prometheus_community
  namespace  = kubernetes_namespace.monitoring.id
  version    = var.prometheus_operator_version
  wait       = false

  set {
    name  = "rbac.create"
    value = "true"
  }

  values = [
    local.kube_prometheus_stack_template
  ]
}

output "grafana_domain_name" {
  value       = local.grafana_domain_name
  description = "Grafana dashboards address"
}

output "alertmanager_domain_name" {
  value       = local.alertmanager_domain_name
  description = "Alertmanager ui address"
}

output "prometheus_domain_name" {
  value       = local.prometheus_domain_name
  description = "Prometheus ui address"
}

output "grafana_admin_password" {
  value       = local.grafana_password
  sensitive   = true
  description = "Grafana admin password"
}


