# ===================================================================================================
#
# This script finds out the leftover users in a federated domain
# without an immutable ID so that the can be moved to a different domain
#
# ===================================================================================================
# Config
$AADUser = "admin@domain.onmicrosoft.com"
$AADPassword = ConvertTo-SecureString 'password' -AsPlainText -Force
$Domain = 'domain.com'
$TargetDomain = 'domain.onmicrosoft.com'
# ===================================================================================================

Import-Module AzureAD
$AADCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($AADUser, $AADPassword)
$stat = Connect-AzureAD -Credential $AADCred

$users = Get-AzureADUser -All $true | `
	Select ImmutableID,UserPrincipalName | `
	Where-Object {$_.ImmutableId -eq $null -AND $_.UserPrincipalName.endsWith("@$Domain")}

foreach ($user in $users) {
	$oldupn = $user.UserPrincipalName
	$newupn = $user.UserPrincipalName.replace($Domain, $TargetDomain)
	Write-Output "Moving $oldupn to $newupn"
	
	Set-AzureADUser `
		-ObjectID $oldupn `
		-UserPrincipalName $newupn
}
