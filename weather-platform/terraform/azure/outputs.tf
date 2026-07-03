output "aks_cluster_name" {
  value       = module.azure_infrastructure.aks_cluster_name
  description = "AKS Cluster Name"
}

output "aks_cluster_endpoint" {
  value       = module.azure_infrastructure.aks_cluster_endpoint
  description = "AKS Cluster API Endpoint"
}

output "acr_login_server" {
  value       = module.azure_infrastructure.acr_login_server
  description = "ACR Login Server"
}

output "resource_group_name" {
  value       = module.azure_infrastructure.resource_group_name
  description = "Azure Resource Group Name"
}

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
