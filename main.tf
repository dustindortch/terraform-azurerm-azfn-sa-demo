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
  name                  = "docs"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Function App
