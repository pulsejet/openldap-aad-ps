# ============================== SETUP ===========================================
# Install the module to connect to Azure
Install-Module MSOnline
# ================================================================================

# ============================== LOGIN ===========================================
# Put in global admin credentials
Import-Module MSOnline
$username = "admin@domain.onmicrosoft.com"
$password = ConvertTo-SecureString 'password' -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
Connect-MSolService -Credential $psCred
# ================================================================================

# ============================== AUTH SETUP ======================================
# SWITCH TO FEDERATED AUTHENTICATION
$dom = "domain.com"
$BrandName = "SSO"
$LogOnUrl = "https://sso.domain.com/saml/azuretest"
$LogOffUrl = "https://sso.domain.com/"
$MyURI = "https://sso.domain.com"
$MySigningCert = "MIIEHDCCAwSgAwIBAgIJAIlHsNqxkDe4MA0GCSqGSIb3DQEFt=="
$Protocol = "SAMLP"
Set-MsolDomainAuthentication `
  -DomainName $dom `
  -FederationBrandName $BrandName `
  -Authentication Federated `
  -PassiveLogOnUri $LogOnUrl `
  -SigningCertificate $MySigningCert `
  -IssuerUri $MyURI `
  -LogOffUri $LogOffUrl `
  -PreferredAuthenticationProtocol $Protocol

# SWITCH TO MANAGED AUTHENTICATION (PASSWORD LOGIN)
$dom = "domain.com"
Set-MsolDomainAuthentication `
  -DomainName $dom `
  -Authentication Managed
# ================================================================================

# ============================== USER MANAGEMENT =================================
# GET FULL USER LIST
Get-MsolUser -All

# GET FULL USER LIST WITh SPECIFIC FIELDS
Get-MsolUser -All | Select ImmutableID,UserPrincipalName,isLicensed

# GET ONE USER ALL INFO
Get-MsolUser -UserPrincipalName "username@domain.com" | Select *

# GET USER BY IMMUTABLEID OR UPN
$uidNumber = 14601
$mail = "username@domain.com"
Get-MsolUser | Where-Object {$_.ImmutableId -eq "$uidNumber" -OR $_.UserPrincipalName -eq $mail}

# CREATE NEW USER
# https://docs.microsoft.com/en-us/powershell/module/msonline/new-msoluser
New-MsolUser `
  -UserPrincipalName "username@domain.com" `
  -ImmutableId 59609 `
  -DisplayName "Varun Patil" `
  -FirstName "Varun" `
  -LastName "Patil" # -LicenseAssignment "SOMETHING NEEDS TO BE HERE"

# UPDATE USER INFO
# https://docs.microsoft.com/en-us/powershell/module/msonline/set-msoluser
Set-MsolUser `
  -UserPrincipalName "username@domain.com" `
  -DisplayName "NEW NAME"

# SET IMMUTABLE ID [CAN BE RUN ONLY WHEN AUTH IN MANAGED MODE, NOT FEDERATED]
# Note: If it is necessary to change immutable ID when in federated, move the user
#       to a different domain first, then change ImmutableID using the new UPN
#       and move the user back to the federated domain
Set-MsolUser -UserPrincipalName "username@domain.com" -ImmutableId 12345
# ================================================================================