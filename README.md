# OpenLDAP-AAD-PS

Powershell script to track changes in OpenLDAP database and export to Azure Active Directory.

Uses the `modifyTimestamp` to keep track of changes happening in OpenLDAP. Configuration must be done in `config.ps1` for Azure AD credentials and your local LDAP database. Note that anonymous bind does not work for some reason.

Some extra useful scripts can be found in `sso_scripts.ps1`. DO NOT run this file!

To run the script
```powershell
.\sync.ps1
```
