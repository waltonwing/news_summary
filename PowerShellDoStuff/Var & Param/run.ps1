# with the correct env session in the yml file, both parameters and variables can be referenced using $env:XXX
# no CmdletBinding or param block is required

write-host "The tenant is T$env:tenantserial, the auther is $env:auther"

if ($env:adxdeploy -eq $true) { # powershell if statement does not recognize yml boolean directly, -eq $true or $false is required
    Write-host "deploy ADX, param status is $env:adxdeploy"
}
else {
    Write-host "not deploying ADX, param status is $env:adxdeploy"
}

$sub=(get-azcontext).Subscription.Id
Write-Host "subscription id is $sub"    #this line is to verify the inputs:azureSubscription line in yml is working correctly