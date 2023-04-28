## ------------------------------------------------------------------------
## Input Parameters
## 
## ------------------------------------------------------------------------

param(
  [Parameter()]
  [String]$resourceGroupName,
  [String]$location,
  [String]$storageAccountName
) 

## ------------------------------------------------------------------------
## Resource Group for State Store
## Check if resource groups exists with name provided, if not create it
## ------------------------------------------------------------------------

echo "*** Check if Resource Group $resourceGroupName exists"
$checkRg = az group exists --name $resourceGroupName | ConvertFrom-Json
if (!$checkRg) {
  Write-Warning "*** WARN! Resource Group $resourceGroupName does not exist. Creating..."
  az group create --name $resourceGroupName --location $location

  if ($LastExitCode -ne 0) {
    throw "*** Error - could not create resource group"
  }
}
else
{
  echo "*** Ok"
}

## ------------------------------------------------------------------------
## Storage Account
## Create storage account for state store
## ------------------------------------------------------------------------

echo "*** Check if Storage Account $storageAccountName exists"
$check = az storage account show --name $storageAccountName --resource-group $resourceGroupName | ConvertFrom-Json
if (!$check) {
  Write-Warning "*** WARN! Storage Account $storageAccountName does not exist. Creating..."

  echo "*** Creating storage account with public-network-access Disabled"
  # If enabling private endpoints down below, we create the storage account with public access disabled to comply with Azure polices that might be in place
  az storage account create --name $storageAccountName `
                            --resource-group $resourceGroupName `
                            --https-only true `
                            --sku Standard_LRS `
                            --min-tls-version TLS1_2 `
                            # --public-network-access Disabled `
                            # --default-action Deny
  if ($LastExitCode -ne 0) {
    throw "*** Error - could not create storage account"
  }

## ------------------------------------------------------------------------
## Private Endpoint
## Create private endpoint for build agents to access state store
## ------------------------------------------------------------------------

  # $peName = "$storageAccountName-pe"

  # $buildAgentResourceGroupName = "" # Needs to be updated with build agent resource group
  # $buildAgentVnetName = ""          # Needs to be updated with build agent vnet name, if applicable 

  # echo "*** Creating Private Endpoints for terraform state storage $storageAccountName"
  # # Create the private endpoint itself
  # az network private-endpoint create `
  # --name $peName `
  # --resource-group $buildAgentResourceGroupName `
  # --vnet-name $buildAgentVnetName `
  # --subnet "private-endpoints-snet" `
  # --private-connection-resource-id $storageAccountId `
  # --group-id blob `
  # --connection-name myConnection

  # if ($LastExitCode -ne 0) {
  #   throw "*** Error - could not create storage private endpoint"
  # }

  # # Create a DNS entry in the private blob.core.windows.net DNS zone of the build agent
  # az network private-endpoint dns-zone-group create `
  # --resource-group $buildAgentResourceGroupName `
  # --endpoint-name $peName `
  # --name "tfprivatednsstorageblob" `
  # --private-dns-zone "privatelink.blob.core.windows.net" `
  # --zone-name blob
  # echo "*** Sleeping for 120 seconds to let the private endpoint become effective"
  # start-sleep -s 120  
}
else
{
  echo "*** Ok"
}

## ------------------------------------------------------------------------
## Resource Lock
## Put a resource lock on the storage account 
## ------------------------------------------------------------------------

echo "*** Set a resource lock on storage account $storageAccountName"
az lock create --name LockStateStore `
        --lock-type CanNotDelete `
        --resource-group $resourceGroupName `
        --resource-name  $storageAccountName `
        --resource-type Microsoft.Storage/storageAccounts

if ($LastExitCode -ne 0) {
  throw "*** Error - could not create resource lock on storage account"
}

$servicePrincipalId = $(az account show --query "user.name" -o tsv)
$storageAccountId = $(az storage account show --name $storageAccountName `
                                              --resource-group $resourceGroupName `
                                              --query "id" -o tsv)

## --------------------------------------------------------------------------------------
## Role Assignment
## Create role assignment for the deploying service principal on the storage account.
## Terraform will then use RBAC to access the storage account instead of account keys
## --------------------------------------------------------------------------------------

$roleName = "Storage Blob Data Owner"
# $principalObjectId=$(az ad signed-in-user show --query objectId -o tsv)


# Check if the role assignment already exists. MUST be generated using a service principal, not specific user
$existingRole = az role assignment list --assignee $servicePrincipalId --role $roleName --scope $storageAccountId | ConvertFrom-Json
# $existingRole = az role assignment list --assignee $principalObjectId --role $roleName --scope $storageAccountId | ConvertFrom-Json

if(-not $existingRole)
{
  echo "*** Creating role assignment $roleName for deploying service principal on $storageAccountId"
  az role assignment create --assignee $servicePrincipalId --role $roleName --scope $storageAccountId
  # az role assignment create --assignee-object-id $principalObjectId --assignee-principal-type "User" --role $roleName --scope $storageAccountId
}
else
{
  echo "*** Role assignment $roleName already exists on Terraform state storage $storageAccountName"
}

if ($LastExitCode -ne 0) {
  throw "*** Error - could not create role assignment"
}

##------------------------------------------------------------------------
## Storage Container
## Create blob storage container for state files
##------------------------------------------------------------------------

$terraformContainerName = "tfstate" # do not change unless you have a strong reason to. If so, also change in 'terraform init' step template
echo "*** Check if Container $terraformContainerName exists"
$check = az storage container exists --account-name $storageAccountName `
                                      --name $terraformContainerName --auth-mode login | ConvertFrom-Json
if (!$check.exists) {
  Write-Warning "*** WARN! Container $terraformContainerName does not exist. Creating..."
  az storage container create --name $terraformContainerName `
                              --account-name $storageAccountName `
                              --public-access off `
                              --auth-mode login

  if ($LastExitCode -ne 0) {
    throw "*** Error - could not create storage container"
  }
}
else
{
  echo "*** Ok"
}

# ------------------------------------------------------------------------
# Storage Account Versioning
# Set versioning properties on blob to enable soft delete
# ------------------------------------------------------------------------

# Enable 7 days soft delete on container and blob-level for the TF state storage account
# The command is idempotent, so we can run it every time without other checks

echo "*** Enabling versioning and soft delete on container- and blob-level"
az storage account blob-service-properties update `
                                          --account-name $storageAccountName `
                                          --resource-group $resourceGroupName `
                                          --enable-versioning true `
                                          --enable-delete-retention true `
                                          --delete-retention-days 7 `
                                          --enable-container-delete-retention true `
                                          --container-delete-retention-days 7
if ($LastExitCode -ne 0) {
  throw "*** Error - could not update storage account properties"
}
