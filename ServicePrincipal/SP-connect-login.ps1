# connect to az with service principle ID and secret, for manual troubleshooting
$ApplicationId = "0a7d3b5b-d976-4bff-957e-2ac44b0419ff"
$userPassword = "cwM8Q~KzaXXyCdqxDN0KeK1623uGrZ.VSNjx9b_t"
$tenantid = "039970ec-d06f-4f60-8f7c-15aebd1c2d5f"

$SecuredPassword = ConvertTo-SecureString -String $userPassword -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecuredPassword
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential #-Environment azureusgovernment

#az login --service-principal -u $ApplicationId -p $userPassword --tenant $tenantid