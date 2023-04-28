#create folder
Set-Location C:\
if (!(test-path .\postdeploy -pathtype container)) {
    New-Item .\postdeploy -Type Directory
}
Set-Location c:\postdeploy

#download and install vs code
Invoke-WebRequest "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -OutFile .\VSCode.exe
./VSCode.exe /VERYSILENT /NORESTART /MERGETASKS=!runcode

#install PS7
Invoke-WebRequest "https://github.com/PowerShell/PowerShell/releases/download/v7.2.2/PowerShell-7.2.2-win-x64.msi" -OutFile .\PowerShell-7.2.2-win-x64.msi
start-process msiexec.exe -wait {/package PowerShell-7.2.2-win-x64.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1}

$ArgumentList1 = {
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -ArgumentList '/I AzureCLI.msi /quiet'
}
start-process pwsh.exe '-C', $ArgumentList1

$ArgumentList2 = {
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Scope AllUsers -Repository PSGallery -Force
}
start-process pwsh.exe '-C', $ArgumentList2

code --install-extension eamodio.gitlens
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension ms-vscode.vscode-node-azure-pack
code --install-extension ms-vscode.azure-account
code --install-extension ms-azuretools.vscode-azureterraform
code --install-extension ms-vscode.powershell
code --install-extension azurepolicy.azurepolicyextension