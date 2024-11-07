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

locals {
  function_apps = { for k, v in var.function_apps : k => merge(
    v,
    {
      name = join("-", [k, random_string.rs.result, "azfn"])
    }
  ) }
}

module "app" {
  source  = "app.terraform.io/acdmy-uto-rbac-1myfdxldfbzt/azfn-asp/azurerm"
  version = "~> 1.0"

  name                 = join("-", [var.app_service_name, random_string.rs.result, "sp"])
  functions            = local.function_apps
  resource_group_name  = data.azurerm_resource_group.rg.name
  location             = data.azurerm_resource_group.rg.location
  storage_account_name = azurerm_storage_account.sa.name
}

resource "azurerm_role_assignment" "fn2sc" {
  for_each = var.function_apps

  scope                = azurerm_storage_container.sc[each.key].resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.app.function_apps[each.key].identity[0].principal_id
}
