# Container App Service
resource "azurerm_linux_web_app" "weather_app" {
  name                = "${var.project_name}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = true
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/${var.project_name}:${var.docker_image_tag}"
      docker_image_tag = var.docker_image_tag
    }
    health_check_path = "/"
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL      = "https://${azurerm_container_registry.acr.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME  = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD  = azurerm_container_registry.acr.admin_password
    GROQ_API_KEY                     = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.groq_api_key.id})"
    WEBSITES_PORT                    = 8000
    ENVIRONMENT                      = var.environment
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Name        = "${var.project_name}-app"
    Environment = var.environment
  }

  depends_on = [azurerm_key_vault_secret.groq_api_key]
}
