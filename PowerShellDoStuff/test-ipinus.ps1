function Test-IPInUS {
    param(
        [string]$IPAddress
    )
    $request = Invoke-WebRequest -Uri "https://azureiplookup.azurewebsites.net/api/ipinfo?ipOrDomain=$IPAddress"
    $result = $request.Content | ConvertFrom-Json
    if (($result.region -contains "eastus") -or ($result.region -contains "westus")) {
        return $true
    } else {
        return $false
    }
}