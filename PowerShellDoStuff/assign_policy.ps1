// powershell to assign azure policy to subscription   
$Subscription = Get-AzSubscription -SubscriptionName 'VSE_Subscription_1'
$Policy = Get-AzPolicyDefinition -id "/subscriptions/a4bee317-3bb4-458d-83ac-1971ff90bbbd/providers/Microsoft.Authorization/policyDefinitions/f3f092ac-a6ca-4297-a4a5-dbe78b9ad6bc"
New-AzPolicyAssignment -Name "No_Resource_Allowed" -PolicyDefinition $Policy -Scope "/subscriptions/$($Subscription.Id)"

Get-AzPolicyassignment -Scope "/subscriptions/$($Subscription.Id)"

remove-AzPolicyAssignment -Name "No_Resource_Allowed" -Scope "/subscriptions/$($Subscription.Id)"