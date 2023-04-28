# Download Azure Migrate Installer
$uri = "https://go.microsoft.com/fwlink/?linkid=2191847"
$download_path = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

try {
    Invoke-WebRequest -Uri $uri -OutFile "$download_path/AzureMigrateInstaller.zip"
}
catch {
    "Unable to download. Please check your internet connection or download from $uri"
}


# check hash
$valid_hash = "1E48D6ACDD8BCD3290F6E1E33705C7AFAAC0745E3295ED56BEF5AC019C0FD760"
$hash = Get-FileHash -Path "$download_path/AzureMigrateInstaller.zip" -Algorithm SHA256

if ($hash.Hash -ne $valid_hash) {
    Write-Host "Hash mismatch. Downloaded file is corrupted."
    exit 1
}
else {
    Write-Host "Hash match. Downloaded file is valid. Extracting..."
}

# extract and run installer
Expand-Archive -Path "$download_path/AzureMigrateInstaller.zip" -DestinationPath "$download_path/AzureMigrateInstaller"
Start-Process -FilePath "$download_path/AzureMigrateInstaller/AzureMigrateInstaller.ps1" -Verb RunAs
