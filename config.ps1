# ============================= CONFIGURATION ====================================
# Global Administrator Credentials for Azure AD
$username = "admin@domain.onmicrosoft.com"
$password = ConvertTo-SecureString 'password' -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)

# LDAP Config
$user = "uid=admin,dc=domain,dc=com"
$pass = "bind-password"
$dn = "LDAP://ldap.domain.com:636/dc=domain,dc=com"
# ================================================================================