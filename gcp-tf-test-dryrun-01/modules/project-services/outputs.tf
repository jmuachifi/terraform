output "enabled_services" {
  description = "Google Cloud APIs enabled for the project."
  value       = sort(keys(google_project_service.enabled))
}
