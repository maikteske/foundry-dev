// Optionale Ubuntu-Jumpbox in snet-privatelink, um interne Smoke-Tests
// (API-Gateway via privatelink-DNS) durchzufuehren. Default: nicht deployen.

@description('Test-VM deployen?')
param deployTestVm bool = false

@description('Name der Test-VM')
param vmName string = 'tbi-vm-ai103plat-test'

@description('Subnet-ID (privatelink)')
param subnetId string

@description('Admin-Benutzer der VM')
param adminUsername string = 'azureuser'

@description('Oeffentlicher SSH-Key der VM')
param sshPublicKey string = ''

@description('CIDR, das SSH auf die VM darf (default: nur der eigene Absender beim ersten Deploy)')
param sshSourcePrefix string = '*'

var pipName = '${vmName}-pip'
var nicName = '${vmName}-nic'
var nsgName = '${vmName}-nsg'

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = if (deployTestVm) {
  name: nsgName
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: sshSourcePrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (deployTestVm) {
  name: pipName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = if (deployTestVm) {
  name: nicName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = if (deployTestVm) {
  name: vmName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        diskSizeGB: 30
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output testVmPublicIp string = deployTestVm ? pip.properties.ipAddress : ''
output testVmPrivateIp string = deployTestVm ? nic.properties.ipConfigurations[0].properties.privateIPAddress : ''
