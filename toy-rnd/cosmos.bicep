param cosmosDBAccountName string = 'toyrnd-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param dbThroughput int = 400
param dbName string = 'toyrnd-cosmosDB-${uniqueString(resourceGroup().id)}'
param containerName string = 'FlightTests'
param partitionKey string = '/droneId'
param storageAccountName string

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosDBAccountName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
  }

  resource cosmosDB 'sqlDatabases' = {
    name: dbName
    properties: {
      resource: {
        id: dbName
      }
      options: {
        throughput: dbThroughput
      }
    }

    resource container 'containers' = {
      name: containerName
      properties: {
        resource: {
          id: containerName
          partitionKey: {
            kind: 'Hash'
            paths: [
              partitionKey
            ]
          }
        }
        options: {}
      }
    }
  }
}

var logAnalyticsWorkspace = 'ToyLogs'
var cosmosDBAccountDiagnosticSettingsName = 'route-logs-to-log-analytics'

resource analWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspace
}

resource cosmosDBAccountDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: cosmosAccount
  name: cosmosDBAccountDiagnosticSettingsName
  properties: {
    workspaceId: analWorkspace.id
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
    ]
  }
}

var storageAccountDiagnostics = 'route-logs-to-log-analytics'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName

  resource blobService 'blobServices' existing = {
    name: 'default'
  }
}

resource azureBlobDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: storageAccount::blobService
  name: storageAccountDiagnostics
  properties: {
    workspaceId: analWorkspace.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
  }
}
