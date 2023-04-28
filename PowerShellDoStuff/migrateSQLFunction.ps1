function Start-MigrateSqlToAzVM {
    <#
    .SYNOPSIS
        Migrate a SQL database to Azure SQL VM
    .DESCRIPTION
        This function perform the following steps in sequence:
        1. Create related resources if not exist
        2. Create a SQL credential on all instances of SQL Server
        3. Create a full backup of target databases to an Azure blob container
        4. Create a migration action
        5. Monitor the migration status and perform cutover when migration is completed
    .PARAMETER  resourceGroupName
        The name of the resource group that contains the Data Migration Service resource.
    .PARAMETER  migrationServiceName
        The name of the Data Migration Service resource.
    .PARAMETER  storageAccountName
        The name of the storage account that contains the blob container.
    .PARAMETER  blobContainerName
        The name of the blob container that contains the backup files.
    .PARAMETER  sourceVmName
        The name of the source SQL Server virtual machine.
    .PARAMETER  sourceUserName
        The user name of the source SQL Server virtual machine.
    .PARAMETER  sourcePassword
        The password of the source SQL Server virtual machine.
    .PARAMETER  sourceDbName
        The name of the source database.
    .PARAMETER  targetVmName
        The name of the target SQL Server virtual machine.
    .PARAMETER  targetDbName
        The name of the target database.
    .EXAMPLE
        PS C:\> Start-MigrateSqlToAzVM -resourceGroupName "rg-sql-migrate" -migrationServiceName "SqlMigrationService123" -storageAccountName "stasqlmigrate123" -blobContainerName "container-migrate123" -sourceVmName "localhost" -sourceUserName <sql admin name> -sourcePassword <sql admin password> -sourceDbName "AdventureWorksSource" -targetVmName "vm-sql-1" -targetDbName "AdventureWroskTarget"
    .INPUTS
        None. You cannot pipe objects to Add-Extension.
    .OUTPUTS
        None.
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]$resourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]$migrationServiceName,
        [Parameter(Mandatory = $true)]
        [string]$storageAccountName,
        [Parameter(Mandatory = $true)]
        [string]$blobContainerName,
        [Parameter(Mandatory = $true)]
        [string]$sourceVmName,
        [Parameter(Mandatory = $true)]
        [string]$sourceUserName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Security.SecureString]$sourcePassword,
        [Parameter(Mandatory = $true)]
        [string]$sourceDbName,
        [Parameter(Mandatory = $true)]
        [string]$targetVmName,
        [Parameter(Mandatory = $true)]
        [string]$targetDbName
    )
    
    #-------------Variables-------------
    
    $resourceGroup = get-azresourcegroup -Name $resourceGroupName
    $targetVmId = (get-azsqlvm -ResourceGroupName $resourceGroup.ResourceGroupName -Name $targetVmName -WarningAction silentlyContinue).resourceid

    #-------------Create resources if not exist-------------

    Write-Host "Checking Data Migration Service resource..."
    $migrationService = Get-AzDataMigrationSqlService -ResourceGroupName $resourceGroup.ResourceGroupName -Name $migrationServiceName -WarningAction silentlyContinue -ErrorAction silentlyContinue
    if ($null -eq $migrationService) {
        $migrationService = New-AzDataMigrationSqlService -ResourceGroupName $resourceGroup.ResourceGroupName -Name $migrationServiceName -Location $resourceGroup.Location -WarningAction silentlyContinue
        Write-Host "Data Migration Service not found. New Data Migration Service resource created."
    }

    write-host "Checking Storage Account..."
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccountName -ErrorAction silentlyContinue
    if ($null -eq $storageAccount) {
        $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccountName -Location $resourceGroup.Location -SkuName Standard_LRS -Kind StorageV2
        Write-Host "Storage Account not found. New Storage Account created."
    }
    $storageaccountid = (Get-AzStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccountName).id
    $storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccountName).Value[0]

    Write-Host "Checking Storage blob container..."
    $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    $container = Get-AzStorageContainer -Name $blobContainerName -Context $storageContext -ErrorAction silentlyContinue
    if ($null -eq $container) {
        New-AzStorageContainer -Name $blobContainerName -Context $storageContext
        Write-Host "Blob container not found. New blob container created."
    }
    
    #-------------Create a SQL credential on all instances of SQL Server-------------

    # load the sqlps module
    import-module sqlps  

    # set parameters
    $sqlPath = "sqlserver:\sql\$($env:COMPUTERNAME)"
    $secureString = ConvertTo-SecureString $storageAccountKey -AsPlainText -Force  
    $credentialName = "migrateCredential-$(Get-Random)"

    Write-Host "Generate credential:" $credentialName
  
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
        -SourceSqlConnectionTrustServerCertificate `
        -WarningAction silentlyContinue

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
}