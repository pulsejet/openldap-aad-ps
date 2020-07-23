# Import modules
# Make sure installed with Install-Module AzureAD
Import-Module AzureAD

# Import functions
. "$($PWD.Path)\config.ps1"
. "$($PWD.Path)\functions.ps1"

# Construct credentials
$AADCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($AADUser, $AADPassword)

# Run sync on all results in filter
function runSyncOnFilter($filter)
{
	$results = LDAPSearch($filter)

	# Connect to Azure only if we have something to work on
	if ($results) {
		Write-Output "$(GetDateString) [DEBUG] LDAP: $(@($results).length) objects found"
		Write-Output "$(GetDateString) [DEBUG] CONNECT: Connecting to Azure AD"
		$stat = Connect-AzureAD -Credential $AADCred
		if (!$?) { exit 1 }
		Write-Output "$(GetDateString) [DEBUG] CONNECT: Successfully connected to Azure AD"
	} else {
		Write-Output "$(GetDateString) [DEBUG] LDAP: No objects found"
		exit 0
	}

	# Run on all users
	foreach ($user in $results)
	{
		syncOneUser($user.properties)
	}
}

# Test on particular users
# runSyncOnFilter("(|(uid=test)(uid=moodi))")
# exit 0

# Get timestamp before starting
$startTimestamp = GetDateString

# Get previous sync time
$lastSync = (Get-Content -Path lastsync.txt).Trim()
if (!$lastSync) { $lastSync = '19700101000000Z' }

# Run sync after previous known time
Write-Output "$(GetDateString) [INFO] Syncing all users modified after $lastSync"
runSyncOnFilter("(&(modifytimestamp>=$lastSync)(uid=*))")

# Put timestamp before we started
Write-Output "$(GetDateString) [INFO] Done syncing all users modified till $startTimestamp"
Set-Content -Path lastsync.txt -Value $startTimestamp
