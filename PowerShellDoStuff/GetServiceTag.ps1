function Get-AzNetworkServiceTagIPv4 {
    <#
    .SYNOPSIS
        Get the IPv4 addresses associated with a service tag
    .DESCRIPTION
        This script requires internet access.
        Takes a service tag name as input and returns the list of IPv4 addresses associated with it. 
        Uses Get-AzNetworkServiceTag to get the service tag information from the Azure API. If failed, it will use the latest service tag JSON from the Microsoft website instead.
    .PARAMETER Tag
        The service tag name, e.g. AzureCloud.eastus
    .PARAMETER Location
        The version of the service tag. This is not a location filter. The default is eastus.
    .EXAMPLE
        Get-AzNetworkServiceTagIPv4 -Tag AzureCloud.eastus
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Tag,
        [string]
        $location = "eastus"
    )

    try {
        $allTags = Get-AzNetworkServiceTag -Location $location # reference of version, not a location filter
    }
    catch {
        try {
            $uri = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519"  # download request page
            $downloadpath = (Invoke-WebRequest $uri).Links.href | Where-Object { $_ -match "ServiceTags_Public_\d+.json" } | Select-Object -First 1  # get the latest redirect url
            $allTags = Invoke-WebRequest $downloadpath | convertfrom-json 
        }
        catch {
            throw "Internet is required"
            exit        
        }
    }    
    
    $targetTag = $allTags.Values | Where-Object { $_.Name -eq $tag }

    try {
        # Your code here
        if ($null -eq $targetTag) {
            throw "Service tag not found."
        }
        else {
            $targetTag.Properties.AddressPrefixes | Where-Object { $_ -match "^\d+\.\d+\.\d+\.\d+\/\d+$" } # Select IPv4 addresses by syntax   
        }
    }
    catch {
        Write-Error $_.Exception.Message -ErrorAction Stop
    }
}
