# ============================= CONFIGURATION ====================================
# Global Administrator Credentials for Azure AD
$AADUser = "admin@domain.onmicrosoft.com"
$AADPassword = ConvertTo-SecureString 'password' -AsPlainText -Force

# LDAP Config
$LDAPUser = "uid=admin,dc=domain,dc=com"
$LDAPPass = "bind-password"
$LDAPDN = "LDAP://ldap.domain.com:636/dc=domain,dc=com"

# LDAP fields for which to create groups [LOWERCASE]
$groupFields = @("employeetype", "enabledapps")
# Prefix for LDAP groups [THIS SHOULD NEVER CHANGE ONCE FIXED]
$groupPrefix = "iitb_ldap"
# ================================================================================