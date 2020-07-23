# Get date in LDAP filter format (UTC)
function GetDateString
{
	return ((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss') + 'Z')
}

# Make a random string
function Get-RandomCharacters($length) {
	$c = 'abcdefghiklmnoprstuvwxyzABCDEFGHKLMNOPRSTUVWXYZ1234567890!@$#%^&*()'
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $c.length }
    $private:ofs = ""
    return [String]$c[$random]
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
	$user = Get-AzureADUser -Filter "ImmutableID eq '$uidNumber' or userPrincipalName eq '$mail'"

	# Check user exists
	if (!$user) {
		echo "$(GetDateString) [WARN] USER_CREATE: $logStr"

		# Create random password
		$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
		$PasswordProfile.Password = Get-RandomCharacters(24)
		$PasswordProfile.EnforceChangePasswordPolicy = $false

		# Create new user
		$newUser = New-AzureADUser `
			-UserPrincipalName $mail `
			-ImmutableId $uidNumber `
			-MailNickName $uid `
			-DisplayName $cn `
			-AccountEnabled $true `
			-PasswordProfile $PasswordProfile

		# Process our new user
		$user = @($newUser)
	}

	# Get first if many
	$user = $user[0]

	# Update the user after creation/check
	echo "$(GetDateString) [INFO] USER_UPDATE: $logStr"

	# Update the user object in Azure AD
	Set-AzureADUser `
		-ObjectID $user.UserPrincipalName `
		-UserPrincipalName $mail `
		-ImmutableId $uidNumber `
		-MailNickName $uid `
		-DisplayName $cn `
		-GivenName $givenName `
		-Surname $sn

	# To get available licenses use Get-MsolAccountSku
	# https://docs.microsoft.com/en-us/office365/enterprise/powershell/assign-licenses-to-user-accounts-with-office-365-powershell
}
