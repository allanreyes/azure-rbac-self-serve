# Modify the values below

$location = "canadaeast"
$resourceGroupName = "rg-rbac-self-serve"

# Deploy the Bicep template

$deployment = New-AzSubscriptionDeployment -Location $location -Name $resourceGroupName -TemplateFile .\infra\main.bicep `
-TemplateParameterObject @{
    location = $location
    resourceGroupName = $resourceGroupName
    approver_email = 'allan.reyes@microsoft.com'
} `
-Verbose

# Using the Azure portal, open the following API Connections, click on Edit API Connection, and authenticate using a service account
# - office365
# - office365groups
# - office365users
# - webcontents
# Make sure you click on Save before navigating away from the Edit API Connection page

# Choose a management group that's in scope and assign the following roles to each managed identity
# Reader > logic-assign-roles
# Role Based Access Control Administrator > logic-assign-roles-apply
# Role Based Access Control Administrator > logic-assign-roles-remove
# For conditions, choose "Allow user to assign all roles except privileged administrator roles Owner, UAA, RBAC (Recommended)"

# Add pre-approved roles to the storage table

Install-Module -Name AzTable -Force -Scope CurrentUser
Import-Module AzTable

$storageName = $deployment.Outputs.storage_name.value
$key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageName | Select-Object -ExpandProperty Value   
$ctx = New-AzStorageContext -StorageAccountName $storageName -StorageAccountKey $key[0]
New-AzStorageContainer -Name preapproved -Context $ctx 

Add-AzTableRow -table $cloudTable -partitionKey role -rowKey "0e5f05e5-9ab9-446b-b98d-1e2157c94125" -property @{ Name = "Quota Request Operator" }
Add-AzTableRow -table $cloudTable -partitionKey role -rowKey "43d0d8ad-25c7-4714-9337-8ba259a9fe05" -property @{ Name = "Monitoring Reader" }
Add-AzTableRow -table $cloudTable -partitionKey role -rowKey "73c42c96-874c-492b-b04d-ab87d138a893" -property @{ Name = "Log Analytics Reader" }
Add-AzTableRow -table $cloudTable -partitionKey role -rowKey "9980e02c-c2be-4d73-94e8-173b1dc7cf3c" -property @{ Name = "Virtual Machine Contributor" }
Add-AzTableRow -table $cloudTable -partitionKey role -rowKey "fa23ad8b-c56e-40d8-ac0c-ce449e1d2c64" -property @{ Name = "Billing Reader" }

# Double check that the pre-approved roles were added to the storage table

$cloudTable = (Get-AzStorageTable -Name preapproved -Context $ctx).CloudTable
Get-AzTableRow -table $cloudTable -partitionKey role | Format-Table

# Copy the Invoke URL to the clipboard and on another file

$invokeUrl = $deployment.Outputs.workflow_url.value
$invokeUrl = $invokeUrl -replace '\?', '/triggers/manual/paths/invoke?'
$invokeUrl | clip

# Paste the Invoke URL in Postaman and send a Post request with the following JSON payload
<#
{
    "name": "NameOfGroupOrServicePrincipal",
    "reason": "asdf",
    "requestedBy": "me@allanreyes.com",
    "requestedFor": "me@allanreyes.com",
    "role": "Contributor",
    "subscriptionId": "a40f4027-37b6-4d60-ad80-33b435300bcd",
    "whatIf": false
}
#>