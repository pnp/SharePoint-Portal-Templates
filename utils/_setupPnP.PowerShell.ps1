<#
.SYNOPSIS
Registers the Entra ID app that PnP.PowerShell uses for interactive sign-in in the destination tenant.
.EXAMPLE
.\utils\_setupPnP.PowerShell.ps1 -Tenant Contoso
#>
[CmdletBinding()]
param(
    # Your tenant name, without the .onmicrosoft.com or .com suffix.
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9-]*$')]
    [string]$Tenant
)

Import-Module PnP.PowerShell -Force

Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP.PowerShell" -Tenant "$($Tenant).onmicrosoft.com"
