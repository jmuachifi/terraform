# Terraform intentionally avoids installing Argo CD directly.
# Argo CD is bootstrapped through the manifests in gitops/bootstrap.
# Apply them once using: kubectl apply -k ../../gitops/bootstrap
