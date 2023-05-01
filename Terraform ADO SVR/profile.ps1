#powershell profile for Terraform connect to waltonchiang.com

#waltonchiang.com
$env:ARM_CLIENT_ID="b6ea1f2f-ba35-45f1-af2f-f3d78fcaf076"
$env:ARM_SUBSCRIPTION_ID="a4bee317-3bb4-458d-83ac-1971ff90bbbd"
$env:ARM_TENANT_ID="039970ec-d06f-4f60-8f7c-15aebd1c2d5f"
$env:ARM_CLIENT_SECRET="z6.7Q~~dd1OqsC_0p-_SfJKx1p91M8DXjPHtr"


#usdcmag.us
$env:ARM_CLIENT_ID="ded3c4e2-6a78-48c2-8926-1786655f25cf"
$env:ARM_SUBSCRIPTION_ID="d0ce61fb-0b7a-4f0d-9ea2-b1ae691749e0"
$env:ARM_TENANT_ID="79e549ba-3a0a-4e0e-b561-ef8f92990834"
$env:ARM_CLIENT_SECRET="f3-9sLI86~95nVtHXzc3q6_-U6_pxXJ~0M"
$env:ARM_environment     ="usgovernment"

gci env:ARM_*
