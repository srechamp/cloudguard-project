terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote state: Terraform reads/writes its state file to this Azure blob
  # instead of a local terraform.tfstate. Backend blocks CANNOT use variables,
  # so the storage_account_name is hardcoded (or supplied via -backend-config).
  backend "azurerm" {
    resource_group_name  = "cloudguard-tfstate-rg"
    storage_account_name = "No hard-coding allowed set via backend-config" # from bootstrap-backend.sh
    container_name       = "tfstate"
    key                  = "jumpbox.tfstate" # the blob (file) name inside the container
  }
}

provider "azurerm" {
  features {}
}
