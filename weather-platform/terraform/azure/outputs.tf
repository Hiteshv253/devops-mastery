output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.weather_app.default_hostname
}

output "app_service_outbound_ip_addresses" {
  description = "Outbound IP addresses of the App Service"
  value       = azurerm_linux_web_app.weather_app.outbound_ip_addresses
}

output "acr_login_server" {
  description = "Login server of the Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Admin username of the Container Registry"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of Application Insights"
  value       = azurerm_application_insights.weather_app.instrumentation_key
}
