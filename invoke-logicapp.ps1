
[CmdletBinding()]
param (
    [string] $name,
    [string] $reason,
    [string] $requestedBy,
    [string] $requestedFor,
    [string] $role,
    [string] $subscriptionId,
    [string] $logicAppUrl
)

$body = @{
  name = $name
  reason = $reason
  requestedBy = $requestedfor
  requestedFor = $requestedfor
  role = $role -Replace ' \*', ''
  subscriptionId = $subscriptionId
  whatIf = $false
}
Write-Host ($body  | ConvertTo-Json)

$result = Invoke-RestMethod -Method Post -Uri $logicAppUrl -Body ($body | ConvertTo-Json) -ContentType 'application/json'

Write-Host $result
