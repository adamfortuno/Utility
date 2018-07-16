/******************************************************************************
.Summary
 Purge Orphan Users

.Description
 Executed at the instance scope. The script identifies and purges orphaned
 users in any of the instance's databases.

 .Example
  Execute the following CREATE USER statements then run the script.

  USE [msdb];
  CREATE USER [deezKats] WITHOUT LOGIN;
  CREATE USER [gorkin] WITHOUT LOGIN;
  USE [master];
  CREATE USER [smuggle] WITHOUT LOGIN;
  CREATE USER [turnup] WITHOUT LOGIN;
  
******************************************************************************/
IF (OBJECT_ID('tempdb..#orphan_purge_activity') IS NOT NULL) DROP TABLE #orphan_purge_activity;

DECLARE @sql_mine_user_information nvarchar(2000);
DECLARE @sql_terminate_user nvarchar(2000);

CREATE TABLE #orphan_purge_activity (
    [database_name] sysname NOT NULL
  , [user_name] sysname NOT NULL
  , create_date datetime NOT NULL
  , count_schemas_owned int NOT NULL
  , count_objects_owned int NOT NULL
  , count_roles_owned int NOT NULL
  , count_procedures_running_as int NOT NULL
  , count_permissions_granted int NOT NULL
  , is_terminated int NOT NULL
);

SET @sql_mine_user_information = '
USE [?];

DECLARE @database_principal_sql_login CHAR(1) = ''S'';
DECLARE @database_principal_windows_login CHAR(1) = ''U'';

INSERT INTO #orphan_purge_activity
SELECT db_name() AS [database_name]
     , usr.name
     , usr.create_date
	 , (SELECT COUNT(*) FROM sys.schemas WHERE principal_id = usr.principal_id) AS [count_schemas_owned]
	 , (SELECT COUNT(*) FROM sys.objects WHERE principal_id = usr.principal_id) AS [count_objects_owned]
	 , (SELECT COUNT(*) FROM sys.database_principals WHERE type = ''R'' AND owning_principal_id = usr.principal_id) AS [count_roles_owned]
	 , (SELECT COUNT(*) FROM sys.sql_modules WHERE execute_as_principal_id = usr.principal_id) AS [count_procedures_running_as]
	 , (SELECT COUNT(*) FROM sys.database_permissions WHERE grantor_principal_id = usr.principal_id) AS [count_permissions_granted]
	 , 0 AS [is_terminated]
  FROM sys.database_principals usr LEFT JOIN sys.server_principals lgn
        ON usr.[sid] = lgn.[sid]
 WHERE usr.type IN (@database_principal_sql_login, @database_principal_windows_login)
   AND usr.principal_id > 4
   AND lgn.[sid] IS NULL;
'
SET @sql_terminate_user = '
USE [?];

DECLARE @terminate_user_cursor as CURSOR;
DECLARE @terminate_user_name as sysname;
DECLARE @sql_user_drop_statement as nvarchar(max);

SET @terminate_user_cursor = CURSOR FAST_FORWARD FOR
SELECT [user_name]
  FROM #orphan_purge_activity
 WHERE [count_schemas_owned] = 0
   AND [count_objects_owned] = 0
   AND [count_roles_owned] = 0
   AND [count_procedures_running_as] = 0
   AND [count_permissions_granted] = 0
   AND is_terminated = 0
   AND [database_name] = ''?'';
 
OPEN @terminate_user_cursor;
FETCH NEXT FROM @terminate_user_cursor INTO @terminate_user_name;

WHILE ( @@FETCH_STATUS = 0 )
 BEGIN
	SET @sql_user_drop_statement = ''DROP USER '' + QUOTENAME(@terminate_user_name);
	EXECUTE (@sql_user_drop_statement);
	UPDATE #orphan_purge_activity SET is_terminated = 1 WHERE [database_name] = ''?'' AND [user_name] = @terminate_user_name;

	FETCH NEXT FROM @terminate_user_cursor INTO @terminate_user_name;
 END

CLOSE @terminate_user_cursor;
DEALLOCATE @terminate_user_cursor;
';

---Identify orphan users on this instance
EXEC sp_msforeachdb @command1 = @sql_mine_user_information;

---Terminate orphan users on this instance
EXEC sp_msforeachdb @command1 = @sql_terminate_user;

---Report back found users as well as whether they 
---were terminated
SELECT * FROM #orphan_purge_activity ORDER BY [database_name];
GO