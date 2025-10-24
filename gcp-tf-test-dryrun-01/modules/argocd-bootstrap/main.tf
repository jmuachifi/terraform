terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
  }
}

locals {
  base_values = {
    global = {
      revisionHistoryLimit = 3
    }
    configs = {
      params = {
        "server.insecure" = "false"
      }
    }
    controller = {
      replicas = 2
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    }
    server = {
      replicas = 2
      service = {
        type = "ClusterIP"
      }
      extraArgs = {
        "insecure" = false
      }
      ingress = {
        enabled          = var.ingress_host != null
        ingressClassName = var.ingress_class_name
        hosts            = var.ingress_host != null ? [var.ingress_host] : []
        tls = var.ingress_host != null ? [
          {
            hosts      = [var.ingress_host]
            secretName = var.tls_secret_name
          }
        ] : []
        annotations = {
          "cert-manager.io/cluster-issuer"               = var.issuer_kind == "ClusterIssuer" ? var.issuer_name : null
          "cert-manager.io/issuer"                       = var.issuer_kind == "Issuer" ? var.issuer_name : null
          "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
        }
      }
    }
    repoServer = {
      autoscaling = {
        enabled                        = true
        minReplicas                    = 2
        maxReplicas                    = 5
        targetCPUUtilizationPercentage = 75
      }
    }
  }

  merged_values = merge(local.base_values, var.additional_settings)
}

resource "kubernetes_namespace" "argocd" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = var.namespace
  timeout    = 600

  create_namespace = false

  values = [yamlencode(local.merged_values)]

  depends_on = [kubernetes_namespace.argocd]
}
