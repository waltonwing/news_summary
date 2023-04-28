

#----------Use Az module to list subscription, use AzureAD module to list AAD roles----------
Login-AzAccount -environment azureusgovernment
Connect-AzureAD -AzureEnvironmentName AzureUSGovernment
#----------Yes you will be prompted to login twice, make sure you're logging to the same tenant----------


#----------Owner and Contributor roles for each subscription----------
$subscriptions = Get-AzSubscription | select-object -Property Name -ExpandProperty Name
$roles = @("Owner", "Contributor")

foreach ($subscription in $subscriptions) {
    foreach ($role in $roles) {
        New-AzureADGroup -DisplayName "$subscription-$role" -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet"
    }
}
#----------Owner and Contributor roles for each subscription----------


#----------Group for every single AAD role----------
$aadRoles = Get-AzureADMSRoleDefinition| select-object -Property DisplayName -ExpandProperty DisplayName

foreach ($role in $aadRoles) {
    New-AzureADGroup -DisplayName "$role" -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet"
}

#----------Group for every single AAD role----------

