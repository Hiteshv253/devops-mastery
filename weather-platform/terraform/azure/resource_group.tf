# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Name        = var.project_name
    Environment = var.environment
  }
}
