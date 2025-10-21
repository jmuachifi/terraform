# Create namespace for NGINX Ingress
resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = var.namespace
  }
}

# Install NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.3"
  namespace  = kubernetes_namespace.nginx_ingress.metadata[0].name

  values = [file("${path.module}/values.yaml")]

  depends_on = [kubernetes_namespace.nginx_ingress]
}
