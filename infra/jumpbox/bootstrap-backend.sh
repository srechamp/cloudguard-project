#!/usr/bin/bash
# Creates the Azure Storage that will HOLD Terraform's remote state.
# This must exist BEFORE `terraform init` - it cannot be managed by the
# same Terraform configuration that stores its state inside it
# (the chicken-and-egg problem). So we create it once, imperatively, here.
set -euo pipefail

LOCATION="eastus2"
RG="cloudguard-tfstate-rg"
CONTAINER="tfstate"
# Storage account names are GLOBALLY unique, 3-24 chars, lowercase letters/digits only.
SA="cloudguardtfstate$(openssl rand -hex 3)"

echo "Creating resource group for state..."
az group create --name "$RG" --location "$LOCATION" -o none

echo "Creating storage account $SA ..."
az storage account create \
  --name "$SA" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  -o none

echo "Creating blob container..."
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA" \
  --auth-mode login \
  -o none

echo ""
echo "=========================================================="
echo "  Backend is ready."
echo "=========================================================="
