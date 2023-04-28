// bicep to create azure resource group
param resourceGroupName string = '12-34'

module alphanumeric './alphanumeric.bicep' = {
  name: 'alphanumeric'
  params: {
    input: resourceGroupName
  }
}

// print the character
output validname string = alphanumeric.outputs.validname
