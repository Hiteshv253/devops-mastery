output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.main.name
  description = "AKS Cluster Name"
}

output "aks_cluster_endpoint" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  description = "AKS Cluster API Endpoint"
}

output "aks_cluster_ca_certificate" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  description = "AKS Cluster CA certificate"
  sensitive   = true
}

output "aks_cluster_client_certificate" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  description = "AKS Cluster Client certificate"
  sensitive   = true
}

output "aks_cluster_client_key" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  description = "AKS Cluster Client Key"
  sensitive   = true
}

output "acr_login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "ACR Login Server"
}

output "acr_admin_username" {
  value       = azurerm_container_registry.main.admin_username
  description = "ACR Admin Username"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Azure Resource Group Name"
}
