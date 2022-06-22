terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }

    azapi = {
      source = "azure/azapi"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

resource "random_pet" "aca" {
  length    = 2
  separator = ""
}

resource "random_integer" "aca" {
  min = 000
  max = 999
}

locals {
  resource_name        = format("%s", random_pet.aca.id)
  resource_name_unique = format("%s%s", random_pet.aca.id, random_integer.aca.result)
  location = "eastus"
}

resource "azurerm_resource_group" "aca" {
  name     = "rg-${local.resource_name}"
  location = local.location

  tags = {
    repo = "pauldotyu/azure-containerapps-terraform"
  }
}

resource "azurerm_container_registry" "aca" {
  name                = "aca${local.resource_name_unique}"
  resource_group_name = azurerm_resource_group.aca.name
  location            = azurerm_resource_group.aca.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_log_analytics_workspace" "aca" {
  name                = "law-${local.resource_name_unique}"
  resource_group_name = azurerm_resource_group.aca.name
  location            = azurerm_resource_group.aca.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# https://registry.terraform.io/providers/Azure/azapi/latest/docs

resource "azapi_resource" "aca_env" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01" # https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/managedenvironments?tabs=bicep
  name      = "env-${local.resource_name}"
  parent_id = azurerm_resource_group.aca.id
  location  = azurerm_resource_group.aca.location

  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.aca.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.aca.primary_shared_key
        }
      }
    }
  })
}

resource "azapi_resource" "hello" {
  type      = "Microsoft.App/containerApps@2022-03-01" #https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/containerapps?tabs=bicep
  name      = "hello-service"
  parent_id = azurerm_resource_group.aca.id
  location  = azurerm_resource_group.aca.location

  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.aca_env.id
      configuration = {
        dapr = {
          appId       = "hello-service"
          appPort     = 8088
          appProtocol = "http"
          enabled     = true
        }
      }
      template = {
        containers = [
          {
            name  = "hello-service"
            image = "ghcr.io/pauldotyu/dapr-demos/hello-service:latest"
          }
        ]
        revisionSuffix = "1"
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })
}

resource "azapi_resource" "world" {
  type      = "Microsoft.App/containerApps@2022-03-01" #https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/containerapps?tabs=bicep
  name      = "world-service"
  parent_id = azurerm_resource_group.aca.id
  location  = azurerm_resource_group.aca.location

  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.aca_env.id
      configuration = {
        dapr = {
          appId       = "world-service"
          appPort     = 8089
          appProtocol = "http"
          enabled     = true
        }
      }
      template = {
        containers = [
          {
            name  = "world-service"
            image = "ghcr.io/pauldotyu/dapr-demos/world-service:latest"
          }
        ]
        revisionSuffix = "1"
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })
}

resource "azapi_resource" "greeting" {
  type      = "Microsoft.App/containerApps@2022-03-01" #https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/containerapps?tabs=bicep
  name      = "greeting-service"
  parent_id = azurerm_resource_group.aca.id
  location  = azurerm_resource_group.aca.location

  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.aca_env.id
      configuration = {
        dapr = {
          appId       = "greeting-service"
          appPort     = 8090
          appProtocol = "http"
          enabled     = true
        }
        ingress = {
          allowInsecure = false
          external      = true
          targetPort    = 8090
          traffic = [
            {
              label          = "dev"
              latestRevision = true
              weight         = 100
            }
          ]
        }
      }
      template = {
        containers = [
          {
            name  = "greeting-service"
            image = "ghcr.io/pauldotyu/dapr-demos/greeting-service:latest"
          }
        ]
        revisionSuffix = "1"
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })

  // this tells azapi to pull out properties and stuff into the output attribute for the object
  response_export_values = ["properties.configuration.ingress.fqdn"]
}

output "ingress_url" {
  value = format("%s%s%s", "https://", jsondecode(azapi_resource.greeting.output).properties.configuration.ingress.fqdn, "/greet")
}

output "resource_group_id" {
  value = azurerm_resource_group.aca.id
}

// todo: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal