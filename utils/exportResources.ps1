Import-Module PnP.PowerShell -Force
Import-Module ./PowerShell/UtilityFunctions.psm1 -Force

Add-SympVariables

# Credimus
$credimusUrl = "https://$($tenant).sharepoint.com/sites/Credimus"
$credimusConnection = Connect-PnPOnline -ClientId $clientId -Url $credimusUrl -Interactive -ReturnConnection

$credimusConfig = Get-PnPListItem `
    -Connection $credimusConnection `
    -List "ConnectionsConfiguration-4ce1892f-76d2-4393-b9df-079a66a95c4a" `
    -Id 1

# Get the Spotlight configuration
$credimusResources = [PSCustomObject]@{
    Title = "Spotlight_x0020_Configuration"
    Value = $credimusConfig.FieldValues["Spotlight_x0020_Configuration"]
}

$credimusResources | Export-Csv -Path "./SPEX002/Resources/Credimus.Resources.csv" -NoTypeInformation -Force



# Solbound
$solboundUrl = "https://$($tenant).sharepoint.com/sites/Solbound"
$solboundConnection = Connect-PnPOnline -ClientId $clientId -Url $solboundUrl -Interactive -ReturnConnection

$solboundConfig = Get-PnPListItem `
    -Connection $solboundConnection `
    -List "ConnectionsConfiguration-4ce1892f-76d2-4393-b9df-079a66a95c4a" `
    -Id 1

# Get the Spotlight configuration
$solboundResources = [PSCustomObject]@{
    Title = "Spotlight_x0020_Configuration"
    Value = $solboundConfig.FieldValues["Spotlight_x0020_Configuration"]
}

$solboundResources | Export-Csv -Path "./SPEX002/Resources/Solbound.Resources.csv" -NoTypeInformation -Force







Get-PnPList -Connection $credimusConnection -Includes Hidden

Get-PnPPropertyBag -Connection $credimusConnection

Get-PnPList -Connection $credimusConnection -Identity "ConnectionsConfiguration4ce1892f76d24393b9df079a66a95c4a"

Get-PnPList -Connection $credimusConnection -Includes RootFolder |
    Select Title,@{N="Url";E={$_.RootFolder.ServerRelativeUrl}}

Get-PnPField -Connection $credimusConnection -List "ConnectionsConfiguration4ce1892f76d24393b9df079a66a95c4a"


Get-PnPListItem -Connection $credimusConnection -List "ConnectionsConfiguration-4ce1892f-76d2-4393-b9df-079a66a95c4a"


Get-PnPListItem -Connection $credimusConnection -List "CompanyList-006e2221-e1df-45c0-8753-83a98de5ecf1"


$item = Get-PnPListItem `
    -Connection $credimusConnection `
    -List "ConnectionsConfiguration-4ce1892f-76d2-4393-b9df-079a66a95c4a" `
    -Id 1

$item.FieldValues

$item.Fieldvalues.Spotlight_x0020_Configuration


Get-PnPField `
  -Connection $credimusConnection `
  -List "ConnectionsConfiguration-4ce1892f-76d2-4393-b9df-079a66a95c4a" |
  Select InternalName,Title



Get-PnpContentType -Connection $credimusConnection -List "ConnectionsConfiguration-4ce1892f-76d2-4393-b9df-079a66a95c4a"
