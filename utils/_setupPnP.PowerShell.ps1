Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "m365x58285237" # Your tenant name, without the .onmicrosoft.com or .com suffix
#endregion

Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP.PowerShell" -Tenant "$($tenant).onmicrosoft.com"