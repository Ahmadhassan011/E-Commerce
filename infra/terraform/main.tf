locals {
  project_name    = "ecommerce"
  environment     = "prod-ci"
  env_safe        = replace(local.environment, "-", "")
  location        = "centralindia"
  tags = {
    Project     = "ecommerce"
    ManagedBy   = "Terraform"
    Environment = "prod-ci"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.project_name}-${local.environment}"
  location = local.location
  tags     = local.tags
}

resource "azurerm_container_registry" "acr" {
  name                = "acrecommerce${local.env_safe}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = local.tags
}

resource "azurerm_service_plan" "app_plan" {
  name                = "asp-${local.project_name}-${local.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = local.tags
}

resource "azurerm_linux_web_app" "backend" {
  name                = "app-${local.project_name}-backend-${local.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.app_plan.id
  https_only          = true
  tags                = local.tags

  site_config {
    always_on       = false
    minimum_tls_version = "1.0"
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/backend"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL         = "https://${azurerm_container_registry.acr.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.acr.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "3500"
    PORT                                = "3500"
    NODE_ENV                            = "production"
    DB_HOST                             = "${azurerm_postgresql_flexible_server.postgresql.name}.postgres.database.azure.com"
    DB_PORT                             = "5432"
    DB_NAME                             = local.project_name
    DB_USER                             = var.postgresql_admin_user
    DB_PASS                             = var.postgresql_admin_password
    JWT_ENCRYPTION_KEY                  = var.jwt_encryption_key
    JWT_AUTH_KEY                        = var.jwt_auth_key
    AUTH_KEY                            = var.jwt_auth_key
    JWT_KEY                             = var.jwt_key
    FRONTEND_SERVER_ORIGIN              = "https://app-${local.project_name}-backend-${local.environment}.azurewebsites.net"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_linux_web_app" "frontend" {
  name                = "app-${local.project_name}-frontend-${local.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.app_plan.id
  https_only          = true
  tags                = local.tags

  site_config {
    always_on       = false
    minimum_tls_version = "1.0"
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/frontend"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL         = "https://${azurerm_container_registry.acr.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.acr.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "3000"
    PORT                                = "3000"
    BACKEND_URL                         = "https://app-${local.project_name}-backend-${local.environment}.azurewebsites.net"
    AUTH_KEY                            = var.jwt_auth_key
    JWT_KEY                             = var.jwt_key
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_postgresql_flexible_server" "postgresql" {
  name                   = "pg-${local.project_name}-${local.environment}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  administrator_login    = var.postgresql_admin_user
  administrator_password = var.postgresql_admin_password
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  zone                   = "3"
  tags                   = local.tags
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.postgresql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = local.project_name
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-${local.project_name}-${local.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  soft_delete_retention_days = 90
  purge_protection_enabled   = false
  tags                       = local.tags
}

resource "azurerm_role_assignment" "current_user_kv_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
  ]
}

resource "azurerm_key_vault_access_policy" "backend_identity" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = azurerm_linux_web_app.backend.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.backend.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

resource "azurerm_key_vault_secret" "db_pass" {
  name         = "DB-PASS"
  value        = var.postgresql_admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "jwt_encryption_key" {
  name         = "JWT-ENCRYPTION-KEY"
  value        = var.jwt_encryption_key
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "jwt_auth_key" {
  name         = "JWT-AUTH-KEY"
  value        = var.jwt_auth_key
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "stripe_key" {
  name         = "STRIPE-SECRET-KEY"
  value        = var.stripe_secret_key
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "smtp_pass" {
  name         = "SMTP-PASS"
  value        = var.smtp_password
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "google_client_secret" {
  name         = "GOOGLE-CLIENT-SECRET"
  value        = var.google_client_secret
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_role_assignment" "backend_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.backend.identity[0].principal_id
}

resource "azurerm_role_assignment" "frontend_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.frontend.identity[0].principal_id
}
