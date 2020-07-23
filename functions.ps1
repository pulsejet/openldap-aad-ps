# Get date in LDAP filter format (UTC)
function GetDateString
{
	return ((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss') + 'Z')
}

# Search for given filter
function LDAPSearch($filter)
{
	$attrs = 'uid', 'uidNumber', 'mail', 'cn', 'sn', 'givenName'
	$auth = [System.DirectoryServices.AuthenticationTypes]::SecureSocketsLayer
	$de = New-Object System.DirectoryServices.DirectoryEntry($LDAPDN, $LDAPUser, $LDAPPass, $auth)
	$ds = New-Object System.DirectoryServices.DirectorySearcher($de, $filter, $attrs)
	$ds.PageSize = 50;
	$result = $ds.FindAll()
	$ds.Dispose()
	return $result
}

# Run sync on one user object
function syncOneUser($user)
{
	$uid = "$($user.uid)"
	$mail = "$($user.mail)"
	$uidNumber = "$($user.uidnumber)"
	$cn = "$($user.cn)"
	$givenName = "$($user.givenname)"
	$sn = "$($user.sn)"

	# Change domain for testing
	# $mail = "$uid@iitb.radialapps.com"

	# Information to log
	$logStr = "uid=$uid mail=$mail uidNumber=$uidNumber"

	# Check vital fields present
	if (!$user.uid -OR !$user.uidnumber -OR !$user.mail) {
		echo "$(GetDateString) [ERROR] MISSING_FIELDS: $logStr"
		return
	}

	# Get user from Azure AD
	$user = (Get-MsolUser | Where-Object {$_.ImmutableId -eq "$uidNumber" -OR $_.UserPrincipalName -eq $mail})

	# Check user exists
	if (!$user) {
		echo "$(GetDateString) [WARN] USER_CREATE: $logStr"
		$newUser = New-MsolUser `
			-UserPrincipalName $mail `
			-ImmutableId $uidNumber `
			-DisplayName $cn
	} else {
		$user = $user[0]

		# Check if UPN has changed
		if ($user.UserPrincipalName -ne $mail) {
			echo "$(GetDateString) [WARN] UPN_CHANGE: $logStr"
			Set-MsolUserPrincipalName `
				-UserPrincipalName $user.UserPrincipalName `
				-NewUserPrincipalName $mail
		}
	}

	# Update the user after creation/check
	echo "$(GetDateString) [INFO] USER_UPDATE: $logStr"

	# Set all other fields and hope ImmutableID never changes
	# To get available licenses use Get-MsolAccountSku
	# https://docs.microsoft.com/en-us/office365/enterprise/powershell/assign-licenses-to-user-accounts-with-office-365-powershell
	Set-MsolUser `
		-UserPrincipalName $mail `
		-ImmutableId $uidNumber `
		-DisplayName $cn `
		-FirstName $givenName `
		-LastName $sn # -LicenseAssignment $AzureLicense
}
