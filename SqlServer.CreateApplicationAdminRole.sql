USE [master];
GO
IF EXISTS (SELECT * FROM sys.server_principals WHERE [name] = 'test_qualys_login' AND [type] = 'S')
	DROP LOGIN [test_qualys_login];
GO
IF EXISTS (SELECT * FROM sys.server_principals WHERE [name] = 'role_vulnerability_scan' AND [type] = 'R')
	DROP SERVER ROLE [role_vulnerability_scan];
GO
CREATE SERVER ROLE [role_vulnerability_scan];
CREATE LOGIN [test_qualys_login] WITH PASSWORD = N'OnePassword2!';
ALTER SERVER ROLE [role_vulnerability_scan] ADD MEMBER [test_qualys_login] 
GO
GRANT CONTROL SERVER TO [role_vulnerability_scan];
DENY ALTER ANY AVAILABILITY GROUP TO [role_vulnerability_scan];
DENY ALTER ANY EVENT SESSION TO [role_vulnerability_scan];
DENY ALTER ANY LOGIN TO [role_vulnerability_scan];
DENY ALTER RESOURCES TO [role_vulnerability_scan];
DENY ALTER ANY LINKED SERVER TO [role_vulnerability_scan];
DENY ALTER TRACE TO [role_vulnerability_scan];
DENY ADMINISTER BULK OPERATIONS TO [role_vulnerability_scan];
DENY ALTER ANY CONNECTION TO [role_vulnerability_scan];
DENY ALTER ANY DATABASE TO [role_vulnerability_scan];
DENY ALTER ANY EVENT NOTIFICATION TO [role_vulnerability_scan];
DENY ALTER ANY ENDPOINT TO [role_vulnerability_scan];
DENY ALTER ANY LOGIN TO [role_vulnerability_scan];
DENY ALTER ANY LINKED SERVER TO [role_vulnerability_scan];
DENY ALTER RESOURCES TO [role_vulnerability_scan];
DENY ALTER SERVER STATE TO [role_vulnerability_scan];
DENY ALTER SETTINGS TO [role_vulnerability_scan];
DENY ALTER TRACE TO [role_vulnerability_scan];
DENY CREATE ANY DATABASE TO [role_vulnerability_scan];
DENY CREATE DDL EVENT NOTIFICATION TO [role_vulnerability_scan];
DENY CREATE ENDPOINT TO [role_vulnerability_scan];
DENY CREATE TRACE EVENT NOTIFICATION TO [role_vulnerability_scan];
DENY SHUTDOWN TO [role_vulnerability_scan];
GO