output "weather_namespace" {
  value       = module.kubernetes_resources.weather_namespace
  description = "Weather application namespace"
}

output "monitoring_namespace" {
  value       = module.kubernetes_resources.monitoring_namespace
  description = "Monitoring namespace"
}

output "argocd_namespace" {
  value       = module.kubernetes_resources.argocd_namespace
  description = "ArgoCD namespace"
}

output "app_release_status" {
  value       = module.kubernetes_resources.app_release_status
  description = "Helm release status"
}
