variable "app_name" {
  description = "The name of the Function App."
  type        = string
}
variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created."
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account."
  type        = string
}

locals {
  valid_storage_account_tiers = ["Standard", "Premium"]
}

variable "storage_account_tier" {
  default     = "Standard"
  description = "The tier of the storage account."
  type        = string

  validation {
    condition     = contains(local.valid_storage_account_tiers, var.storage_account_tier)
    error_message = "The value of storage_account_tier must be either ${join(", ", local.valid_storage_account_tiers)}."
  }
}

locals {
  valid_storage_account_replication_types = ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"]
}

variable "storage_account_replication_type" {
  default     = "LRS"
  description = "The replication type of the storage account."
  type        = string

  validation {
    condition     = contains(local.valid_storage_account_replication_types, var.storage_account_replication_type)
    error_message = "The value of storage_account_replication_type must be either ${join(", ", local.valid_storage_account_replication_types)}."
  }
}
