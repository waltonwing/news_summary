function New-Password {
    <#
    .SYNOPSIS
        Generate a random password
    .DESCRIPTION
        Generate a random password with a specified number of special characters, numbers, uppercase letters, and lowercase letters. 0-255 of each type can be specified. The default is 3 of each type.
    .PARAMETER Upper
        Number of uppercase letters to include in the password
    .PARAMETER Lower
        Number of lowercase letters to include in the password
    .PARAMETER Number
        Number of numbers to include in the password
    .PARAMETER Special
        Number of special characters to include in the password
    .EXAMPLE
        New-Password -Special 1 -Number 2 -Upper 3 -Lower 4
        Uh0Wa:z7dQ  
        WARNING: Do not use this password. It is only an example.
    .INPUTS
        None. You cannot pipe objects to Add-Extension.
    .OUTPUTS
        String
    #>

    param(
        [int]
        [ValidateScript({$_ -ge 0})]
        $Upper = 3,
        [int]
        [ValidateScript({$_ -ge 0})]
        $Lower = 3,
        [int]
        [ValidateScript({$_ -ge 0})]
        $Number = 3,
        [int]
        [ValidateScript({$_ -ge 0})]
        $Special = 3
    )

    # if the value of Count exceeds the number of objects in the collection, Get-Random returns all of the objects in random order
    # use For loop instead of Get-Random -Count to avoid limit and allow same character to be used multiple times
    $rawUpper = @()
    for (($Upper); ($Upper -gt 0); ($Upper--)) {
        $rawUpper += (65..90) | Get-Random | ForEach-Object { [char]$_ }
    }

    $rawLower = @()
    for (($Lower); ($Lower -gt 0); ($Lower--)) {
        $rawLower += (97..122) | Get-Random  | ForEach-Object { [char]$_ }
    }

    $rawNumber = @()
    for (($Number); ($Number -gt 0); ($Number--)) {
        $rawNumber += (0..9) | Get-Random
    }

    $rawSpecial = @()
    for (($Special); ($Special -gt 0); ($Special--)) {
        $rawSpecial += (33..47) + (58..64) + (91..96) + (123..126) | Get-Random | ForEach-Object { [char]$_ }
    }
        
    # use -join to change array to string
    return -join (Get-Random -shuffle $($rawUpper + $rawLower + $rawNumber + $rawSpecial))
}