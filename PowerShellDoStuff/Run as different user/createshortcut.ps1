#-----------------get credential------------------------------
$password = "SUPERnova11@@##9"
$username = "waltonwing"
$password = ConvertTo-SecureString $password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($username, $password)

#--------------get exe path--------------------
$exe = (Read-Host "Exe full path, default PowerShell") 
if (!$exe) {
    Write-host "Using PowerShell for testing..." -ForegroundColor Yellow
    $exe = "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe"    
}
else {
    Start-Process -filepath $exe -Credential $Credential
}

#----------------create shortcut in desktop-----------------
$WshShell = New-Object -comObject WScript.Shell
$exename = Split-Path $exe -Leaf
$Shortcut = $WshShell.CreateShortcut("$env:systemdrive\$exename.lnk")
$Shortcut.TargetPath = "runas"
$Shortcut.Arguments = " /user:demo\waltonwing /savecred $exe" 
$Shortcut.Save()

#-------------------run shortcut-----------------------------------
#Start-Process "$Home\Desktop\$exename.lnk" -Credential $Credential