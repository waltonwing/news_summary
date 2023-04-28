# Generate a random AES Encryption Key.
$AESKey = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
	
# Store the AESKey into a file. This file should be protected!  (e.g. ACL on the file to allow only select people to read)
Set-Content -path .\key -value $AESKey   # Any existing AES Key file will be overwritten		

$password = (Read-Host "Password" -AsSecureString) | ConvertFrom-SecureString -Key $AESKey
Add-Content .\cred.xml $password