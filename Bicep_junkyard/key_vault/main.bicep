// parameter random password
@secure()
param password string = newGuid() //Can only be used as the default value for a param

param location string = 'eastus'

// bicep key vault resource
resource KeyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'testvault1206'
  location: location
  properties: {
    enableSoftDelete: false
    publicNetworkAccess: 'Enabled'
    accessPolicies: [
    ]
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: '039970ec-d06f-4f60-8f7c-15aebd1c2d5f'
  }
}

resource KVSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'testpassword1206'
  parent: KeyVault
  properties: {
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
    value: password
  }
}

// bicep virtual network resource
resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'testvnet1206'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'testsubnet1206'
        properties: {
          addressPrefix: '10.0.0.0/25'
        }
      }
    ]
  }
}

// bicep network interface resource
resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'testnic1206'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'testipconfig1206'
        properties: {
          subnet: {
            // id: '/subscriptions/039970ec-d06f-4f60-8f7c-15aebd1c2d5f/resourceGroups/testrg1206/providers/Microsoft.Network/virtualNetworks/testvnet1206/subnets/testsubnet1206'
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}
// windows virtual machine resource
resource WindowsVM 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: 'testvm1206'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      adminPassword: password
      adminUsername: 'waltonchiang'
      computerName: 'testvm1206'
    }
  }
}
