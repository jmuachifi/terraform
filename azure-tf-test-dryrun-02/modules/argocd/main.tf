# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

# Install ArgoCD via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      enable_workload_identity = var.enable_workload_identity
      oidc_issuer_url          = var.oidc_issuer_url
    })
  ]

  set = [
    {
      name  = "server.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "server.extraArgs[0]"
      value = "--insecure"
    }
  ]

  depends_on = [kubernetes_namespace.argocd]
}
