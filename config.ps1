# ============================= CONFIGURATION ====================================
# Global Administrator Credentials for Azure AD
$AADUser = "admin@domain.onmicrosoft.com"
$AADPassword = ConvertTo-SecureString 'password' -AsPlainText -Force

# LDAP Config
$LDAPUser = "uid=admin,dc=domain,dc=com"
$LDAPPass = "bind-password"
$LDAPDN = "LDAP://ldap.domain.com:636/dc=domain,dc=com"
# ================================================================================