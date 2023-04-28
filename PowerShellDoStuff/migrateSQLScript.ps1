# Install-Module -Name Az.DataMigration

#-------------Parameters-------------

$resourceGroupName = "rg-sql-migrate"
$migrationServiceName = "SqlMigrationService258"
$storageAccountName = "stasqlmigrate414"
$blobContainerName = "container-migrate258"
$sourceVmName = "localhost"
$sourceUserName = "NORTHAMERICA\waltonchiang"
$sourceDbName = "AdventureWorksSource"
$sourcePassword = Read-Host "Source SQL database password" -AsSecureString
$targetVmName = "vm-sql-1"
$targetDbName = "AdventureWroskTarget258"

#-------------Variables-------------

$resourceGroup = get-azresourcegroup -Name $resourceGroupName
$targetVmId = (get-azsqlvm -ResourceGroupName $resourceGroup.ResourceGroupName -Name $targetVmName -WarningAction silentlyContinue).resourceid
$storageaccountid = (Get-AzStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccountName).id
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccountName).Value[0]

#-------------Create Data Migration Service resource if not exist-------------

$migrationService = Get-AzDataMigrationSqlService -ResourceGroupName $resourceGroup.ResourceGroupName -Name $migrationServiceName -WarningAction silentlyContinue

if ($null -eq $migrationService) {
    $migrationService = New-AzDataMigrationSqlService -ResourceGroupName $resourceGroup.ResourceGroupName -Name $migrationServiceName -Location $resourceGroup.Location
    write-host "Data Migration Service not found. New Data Migration Service resource created."
}

#-------------Create a SQL credential on all instances of SQL Server-------------

# load the sqlps module
import-module sqlps  

# set parameters
$sqlPath = "sqlserver:\sql\$($env:COMPUTERNAME)"
$secureString = ConvertTo-SecureString $storageAccountKey -AsPlainText -Force  
$credentialName = "myCredential-$(Get-Random)"

Write-Host "Generate credential: " $credentialName
  
#cd to sql server and get instances  
Set-Location $sqlPath
$instances = Get-ChildItem

#loop through instances and create a SQL credential, output any errors
foreach ($instance in $instances) {
    try {
        $path = "$($sqlPath)\$($instance.DisplayName)\credentials"
        New-SqlCredential -Name $credentialName -Identity $storageAccountName -Secret $secureString -Path $path -ea Stop | Out-Null
        Write-Host "...generated credential $($path)\$($credentialName)."  
    }
    catch { Write-Host $_.Exception.Message } 
}

#-------------Full backup for target databases-------------

#create blob container if not exist
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$container = Get-AzStorageContainer -Name $blobContainerName -Context $storageContext
if ($null -eq $container) {
    New-AzStorageContainer -Name $blobContainerName -Context $storageContext
    Write-Host "Blob container not found. New blob container created."
}

$backupUrlContainer = "https://$storageAccountName.blob.core.windows.net/$blobContainerName/"  

Write-Host "Backup location:" $backupUrlContainer

Set-Location $sqlPath
$instances = Get-ChildItem

#loop through instances and backup target databases
foreach ($instance in $instances) {
    $path = "$($sqlPath)\$($instance.DisplayName)\databases"
    $databases = Get-ChildItem -Force -Path $path | Where-object { $_.name -eq $sourceDbName }

    foreach ($database in $databases) {
        try {
            $databasePath = "$($path)\$($database.Name)"
            Write-Host "...starting backup: " $databasePath
            Backup-SqlDatabase -Database $database.Name -Path $path -BackupContainer "$backupUrlContainer$sourceDbName/" -SqlCredential $credentialName #-Compression On
            Write-Host "...backup complete."  
        }
        catch { Write-Host $_.Exception.Message } 
    } 
}

#-------------CREATE MIGRATION ACTION-------------

New-AzDataMigrationToSqlVM `
    -ResourceGroupName $resourceGroup.ResourceGroupName `
    -SqlVirtualMachineName $targetVmName `
    -TargetDbName $targetDbName `
    -Kind "SqlVM" `
    -Scope $targetVmId `
    -MigrationService $migrationService.id `
    -AzureBlobStorageAccountResourceId $storageaccountid `
    -AzureBlobAccountKey $storageAccountKey `
    -AzureblobContainer "$blobContainerName/$sourceDbName" `
    -SourceSqlConnectionAuthentication "SqlAuthentication" `
    -SourceSqlConnectionDataSource $sourceVmName `
    -SourceSqlConnectionUserName $sourceUserName `
    -SourceSqlConnectionPassword $sourcePassword `
    -SourceDatabaseName $sourceDbName `
    -SourceSqlConnectionTrustServerCertificate

#----------Monitoring Migration----------

for ($true) {
    $vmMigration = Get-AzDataMigrationToSqlVM -ResourceGroupName $resourceGroup.ResourceGroupName -SqlVirtualMachineName $targetVmName -TargetDbName $targetDbName -WarningAction silentlyContinue
    if ($vmMigration.MigrationStatus -eq "ReadyForCutover") {
        Invoke-AzDataMigrationCutoverToSqlVM -ResourceGroupName $resourceGroup.ResourceGroupName -SqlVirtualMachineName $targetVmName -TargetDbName $targetDbName -MigrationOperationId $vmMigration.MigrationOperationId
        Write-Host "Cutover completed."
        break
    }
    else {
        Write-Host "Migration status: $($vmMigration.MigrationStatus), check again in 30 seconds..."
        Start-Sleep -Seconds 30
    }
}
