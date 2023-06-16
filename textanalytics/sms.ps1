$url = "https://api.twilio.com/2010-04-01/Accounts/ACbd0d26ef725cb220bf6e68d3fe4f9870/Messages.json"
$params = @{
  To = "+14159881905"
  From = "+18449942627"
  Body = "Hello from Twilio"
}
$secret = "74ca84b32c05f9c9a2ae62c45d8b4f17" |
ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("ACbd0d26ef725cb220bf6e68d3fe4f9870", $secret)
Invoke-WebRequest $url -Method Post -Credential $credential -Body $params -UseBasicParsing |
ConvertFrom-Json | Select sid, body