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
	$attrs = 'uid', 'uidNumber', 'mail', 'cn', 'sn', 'givenName', 'mailalternateaddress'
	$attrs = $attrs + $groupFields

	$auth = [System.DirectoryServices.AuthenticationTypes]::SecureSocketsLayer
	$de = New-Object System.DirectoryServices.DirectoryEntry($LDAPDN, $LDAPUser, $LDAPPass, $auth)
	$ds = New-Object System.DirectoryServices.DirectorySearcher($de, $filter, $attrs)
	$ds.PageSize = 50;
	$result = $ds.FindAll()
	$ds.Dispose()
	return $result
}

# Run sync on one user object
function syncOneUser($luser)
{
	$uid = "$($luser.uid)"
	$mail = "$($luser.mail)"
	$uidNumber = "$($luser.uidnumber)"
	$cn = "$($luser.cn)"
	$givenName = "$($luser.givenname)"
	$sn = "$($luser.sn)"

	# Change domain for testing
	# $mail = "$uid@iitb.radialapps.com"

	# Information to log
	$logStr = "uid=$uid mail=$mail uidNumber=$uidNumber"

	# Check vital fields present
	if (!$luser.uid -OR !$luser.uidnumber -OR !$luser.mail) {
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

	# Get alternate email addresses of user
	$alternateMailAddresses = $null
	if ($luser.mailalternateaddress) {
		$alternateMailAddresses = @($luser.mailalternateaddress)
	}

	# Get user groups
	$existingGroups = Get-AzureADUserMembership -ObjectID $mail
	$existingGroupNames = @($existingGroups.DisplayName)
	$newGroupNames = @()

	# Get target groups
	foreach ($field in $groupFields) {
		if ($luser.contains($field) -AND $luser[$field]) {
			foreach ($fval in @($luser[$field])) {
				$groupName = "$($groupPrefix)_$($field.ToLower())_$($fval.ToLower())"
				$newGroupNames += $groupName

				# Check if user already has group
				if ($existingGroupNames -cnotcontains $groupName) {
					# Check if group already exists
					$grp = Get-AzureADGroup -Filter "DisplayName eq '$groupName'"

					# Create new group
					if (!$grp) {
						echo "$(GetDateString) [WARN] NEW_GROUP: $groupName"
						$grp = New-AzureADGroup `
							-DisplayName $groupName `
							-MailEnabled $false `
							-SecurityEnabled $true `
							-MailNickName $groupName
					}

					# Add to group
					echo "$(GetDateString) [INFO] USER_ADD_GROUP: $uid=$groupName"
					Add-AzureADGroupMember `
						-ObjectId $grp.ObjectID `
						-RefObjectId $user.ObjectID
				}
			}
		}
	}

	# Check existing groups from which the user has to be removed
	foreach ($grp in $existingGroups) {
		if ($grp.DisplayName.startsWith("$($groupPrefix)_") -AND $newGroupNames -cnotcontains $grp.DisplayName) {
			echo "$(GetDateString) [INFO] USER_REM_GROUP: $uid=$($grp.DisplayName)"
			Remove-AzureADGroupMember `
				-ObjectId $grp.ObjectID `
				-MemberId $user.ObjectID
		}
	}

	# Update the user object in Azure AD
	Set-AzureADUser `
		-ObjectID $user.UserPrincipalName `
		-UserPrincipalName $mail `
		-ImmutableId $uidNumber `
		-MailNickName $uid `
		-DisplayName $cn `
		-GivenName $givenName `
		-Surname $sn `
		-OtherMails $alternateMailAddresses

	# To get available licenses use Get-MsolAccountSku
	# https://docs.microsoft.com/en-us/office365/enterprise/powershell/assign-licenses-to-user-accounts-with-office-365-powershell
}
