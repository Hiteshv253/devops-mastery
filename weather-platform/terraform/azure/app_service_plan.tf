# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${var.project_name}-asp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "${var.sku_tier}-${var.sku_size}"

  tags = {
    Name        = "${var.project_name}-asp"
    Environment = var.environment
  }
}
