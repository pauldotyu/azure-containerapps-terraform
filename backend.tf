terraform {
  cloud {
    organization = "pauldotyu"

    workspaces {
      name = "azure-containerapps-terraform"
    }
  }
}