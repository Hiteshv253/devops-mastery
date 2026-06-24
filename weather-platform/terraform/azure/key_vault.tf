# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "${replace(var.project_name, "-", "")}-kv"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover"
    ]
  }

  tags = {
    Name        = "${var.project_name}-kv"
    Environment = var.environment
  }
}

# Key Vault Secret for Groq API Key
resource "azurerm_key_vault_secret" "groq_api_key" {
  name         = "groq-api-key"
  value        = var.groq_api_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}

# Data source for client config
data "azurerm_client_config" "current" {}
