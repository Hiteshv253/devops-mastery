# Application Insights
resource "azurerm_application_insights" "weather_app" {
  name                = "${var.project_name}-ai"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id

  tags = {
    Name        = "${var.project_name}-ai"
    Environment = var.environment
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

# Alert Rules
resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "${var.project_name}-cpu-high"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  scopes              = [azurerm_linux_web_app.weather_app.id]
  description         = "Alert when CPU usage is high"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name       = "CpuPercentage"
    aggregation       = "Average"
    operator          = "GreaterThan"
    threshold         = 80
    dimension {
      name     = "ResourceId"
      operator = "Include"
      values   = [azurerm_linux_web_app.weather_app.id]
    }
  }

  frequency  = "PT5M"
  window_size = "PT15M"

  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }
}

# Action Group
resource "azurerm_monitor_action_group" "alerts" {
  name                = "${var.project_name}-alerts"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  short_name          = "weather-alerts"

  email_receiver {
    name                    = "admin"
    email_address           = "admin@example.com"
    use_common_alert_schema = true
  }

  tags = {
    Name        = "${var.project_name}-alerts"
    Environment = var.environment
  }
}
