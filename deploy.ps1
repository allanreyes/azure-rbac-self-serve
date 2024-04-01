$location = "canadaeast"
$resourceGroupName = "rg-rbac-self-serve"

$deployment = New-AzSubscriptionDeployment -Location $location -Name $resourceGroupName -TemplateFile .\infra\main.bicep `
-TemplateParameterObject @{
    location = $location
    resourceGroupName = $resourceGroupName
    approver_email = 'allan.reyes@microsoft.com'
} `
-Verbose

 
$invokeUrl = $deployment.Outputs.workflow_url.value

$invokeUrl = $invokeUrl -replace '\?', '/triggers/manual/paths/invoke?'

$invokeUrl | clip


# $roleDef = Get-Content .\rbac-export.json | ConvertFrom-Json
# $roleDef | Select-Object -ExpandProperty properties | Select-Object roleName | Sort-Object roleName