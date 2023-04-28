if (Test-Path .\cred.xml) {   
    $Credential = Import-Clixml -path .\cred.xml
}
else {
    $Credential = Get-Credential | export-clixml -path .\cred.xml
}


$exe = (Read-Host "Exe full path") 
if (!$exe) {
    Write-host "For testing, running cmd..."
    $exe = "$env:SystemRoot\system32\cmd.exe"    
    Start-Process -filepath $exe -Credential $Credential
}
else {
    Start-Process -filepath $exe -Credential $Credential
}
