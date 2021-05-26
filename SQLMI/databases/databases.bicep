
resource symbolicname 'Microsoft.Sql/managedInstances/databases@2020-11-01-preview' = {
  name: 'string'
  location: 'string'
  tags: {}
  properties: {
    collation: 'string'
    restorePointInTime: 'string'
    catalogCollation: 'string'
    createMode: 'string'
    storageContainerUri: 'string'
    sourceDatabaseId: 'string'
    restorableDroppedDatabaseId: 'string'
    storageContainerSasToken: 'string'
    recoverableDatabaseId: 'string'
    longTermRetentionBackupResourceId: 'string'
    autoCompleteRestore: bool
    lastBackupName: 'string'
  }
}
