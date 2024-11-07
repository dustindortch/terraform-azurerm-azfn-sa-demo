variable "app_service_name" {
  description = "The name of the Function App."
  type        = string
}

variable "function_apps" {
  description = "A map of function apps to create."
  type = map(object({
    runtime = object({
      name    = optional(string, "powershell")
      version = string
    })
  }))

  validation {
    condition = alltrue([
      for k, v in var.function_apps : contains(["powershell", "python"], v.runtime.name)
    ])
    error_message = "The function apps runtime can be only powershell or python."
  }

  validation {
    condition = alltrue(flatten([
      [
        for k, v in var.function_apps : contains(["7", "7.2", "7.4"], v.runtime.version) if v.runtime.name == "powershell"
      ],
      [
        for k, v in var.function_apps : contains(["3.7", "3.8", "3.9", "3.10", "3.11", "3.12"], v.runtime.version) if v.runtime.name == "python"
      ]
    ]))
    error_message = "The function apps runtime version can be only 7.4 or 3.8."
  }
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
