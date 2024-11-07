terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.8"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "random_string" "rs" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_storage_account" "sa" {
  name                     = join("", [var.storage_account_name, random_string.rs.result])
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
}

resource "azurerm_storage_container" "sc" {
  for_each = var.function_apps

  name                  = each.key
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_service_plan" "sp" {
  name                = join("-", [var.app_service_name, random_string.rs.result, "sp"])
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "fa" {
  for_each = var.function_apps

  name                          = join("-", [each.key, random_string.rs.result, "azfn"])
  location                      = data.azurerm_resource_group.rg.location
  resource_group_name           = data.azurerm_resource_group.rg.name
  service_plan_id               = azurerm_service_plan.sp.id
  storage_uses_managed_identity = true
  storage_account_name          = azurerm_storage_account.sa.name

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      powershell_core_version = each.value.runtime.name == "powershell" ? each.value.runtime.version : null
      python_version          = each.value.runtime.name == "python" ? each.value.runtime.version : null
    }
  }
}

resource "azurerm_role_assignment" "fn2sc" {
  for_each = var.function_apps

  scope                = azurerm_storage_container.sc[each.key].resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.fa[each.key].identity[0].principal_id
}
