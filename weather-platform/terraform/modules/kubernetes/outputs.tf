output "weather_namespace" {
  value       = kubernetes_namespace.weather.metadata[0].name
  description = "Weather application namespace"
}

output "monitoring_namespace" {
  value       = kubernetes_namespace.monitoring.metadata[0].name
  description = "Monitoring namespace"
}

output "argocd_namespace" {
  value       = kubernetes_namespace.argocd.metadata[0].name
  description = "ArgoCD namespace"
}

output "app_release_status" {
  value       = helm_release.weather_platform.status
  description = "Status of the deployed Helm release"
}
