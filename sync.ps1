# Import modules
# Make sure installed with Install-Module MSOnline
Import-Module MSOnline

# Import functions
. "$($PWD.Path)\config.ps1"
. "$($PWD.Path)\functions.ps1"

# Run sync on all results in filter
function runSyncOnFilter($filter)
{
	$results = LDAPSearch($filter)

	# Connect to Azure only if we have something to work on
	if ($results) {
		echo "$(GetDateString) [DEBUG] LDAP: $(@($results).length) objects found"
		echo "$(GetDateString) [DEBUG] CONNECT: Connecting to Azure AD"
		Connect-MSolService -Credential $psCred
		if (!$?) { exit 1 }
		echo "$(GetDateString) [DEBUG] CONNECT: Successfully connected to Azure AD"
	} else {
		echo "$(GetDateString) [DEBUG] LDAP: No objects found"
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
echo "$(GetDateString) [INFO] Syncing all users modified after $lastSync"
runSyncOnFilter("(&(modifytimestamp>=$lastSync)(uid=*))")

# Put timestamp before we started
$t = GetDateString
echo "$(GetDateString) [INFO] Done syncing all users modified till $startTimestamp"
Set-Content -Path lastsync.txt -Value $startTimestamp