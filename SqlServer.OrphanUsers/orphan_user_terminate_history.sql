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
IF (OBJECT_ID('tempdb..##orphan') IS NOT NULL) DROP TABLE ##orphan;
IF (OBJECT_ID('tempdb..#orphan_dependency') IS NOT NULL) DROP TABLE #orphan_dependency;

DECLARE @sql_collect_orphan nvarchar(2000);
DECLARE @sql_collect_orphan_dependencies nvarchar(2000);
DECLARE @sql_terminate_orphan nvarchar(2000);

CREATE TABLE ##orphan (
    [database_name] sysname
  , [name] sysname
  , [create_date] datetime
  , [principal_id] int
);

CREATE TABLE #orphan_dependency (
    [database_name] sysname NOT NULL
  , [user_name] sysname NOT NULL
  , [principal_id] int NOT NULL
  , [create_date] datetime NOT NULL
  , [object_type] sysname NULL --schema, object, role, procedure, permission
  , [object_name] sysname NULL
  , [is_terminated] bit default(0)
);

SET @sql_collect_orphan = '
USE [?];

DECLARE @database_principal_sql_login CHAR(1) = ''S'';
DECLARE @database_principal_windows_login CHAR(1) = ''U'';
TRUNCATE TABLE ##orphan;

INSERT INTO ##orphan
SELECT db_name()
, usr.name
, usr.create_date
, usr.principal_id
FROM sys.database_principals usr LEFT JOIN sys.server_principals lgn
ON usr.[sid] = lgn.[sid]
WHERE usr.type IN (@database_principal_sql_login, @database_principal_windows_login)
AND usr.principal_id > 4
AND lgn.[sid] IS NULL;
'

SET @sql_collect_orphan_dependencies = '
USE [?];

INSERT INTO #orphan_dependency (database_name, user_name, principal_id, create_date, object_type, object_name)
SELECT usr.database_name
, usr.[name]
, usr.principal_id
, usr.create_date
, ''schema''
, schm.name
FROM ##orphan usr INNER JOIN sys.schemas schm
ON schm.principal_id = usr.principal_id;

INSERT INTO #orphan_dependency (database_name, user_name, principal_id, create_date, object_type, object_name)
SELECT usr.database_name
, usr.[name]
, usr.principal_id
, usr.create_date
, ''object''
, obj.name
FROM ##orphan usr INNER JOIN sys.objects obj
ON obj.principal_id = usr.principal_id;

INSERT INTO #orphan_dependency (database_name, user_name, principal_id, create_date, object_type, object_name)
SELECT usr.database_name
, usr.[name]
, usr.principal_id
, usr.create_date
, ''role''
, rol.name
FROM ##orphan usr INNER JOIN sys.database_principals rol
ON rol.type = ''R'' AND rol.owning_principal_id = usr.principal_id;

INSERT INTO #orphan_dependency (database_name, user_name, principal_id, create_date, object_type, object_name)
SELECT usr.database_name
, usr.[name]
, usr.principal_id
, usr.create_date
, ''module''
, object_name(smod.object_id)
FROM ##orphan usr INNER JOIN sys.sql_modules smod
ON smod.execute_as_principal_id = usr.principal_id;

INSERT INTO #orphan_dependency (database_name, user_name, principal_id, create_date, object_type, object_name)
SELECT usr.database_name
, usr.[name]
, usr.principal_id
, usr.create_date
, ''permission''
, perm.permission_name
FROM ##orphan usr INNER JOIN sys.database_permissions perm
ON perm.grantor_principal_id = usr.principal_id;

INSERT INTO #orphan_dependency (database_name, user_name, principal_id, create_date)
SELECT usr.database_name
, usr.[name]
, usr.principal_id
, usr.create_date
FROM ##orphan usr LEFT JOIN #orphan_dependency list
ON usr.[principal_id] = list.[principal_id]
WHERE list.[principal_id] IS NULL
'

SET @sql_terminate_orphan = '
USE [?];

DECLARE @terminate_user_cursor as CURSOR;
DECLARE @terminate_user_name as sysname;
DECLARE @sql_user_drop_statement as nvarchar(max);

SET @terminate_user_cursor = CURSOR FAST_FORWARD FOR
SELECT [user_name]
  FROM #orphan_dependency
 WHERE [object_type] IS NULL
   AND [object_name] IS NULL
   AND is_terminated = 0
   AND [database_name] = ''?'';
 
OPEN @terminate_user_cursor;
FETCH NEXT FROM @terminate_user_cursor INTO @terminate_user_name;

WHILE ( @@FETCH_STATUS = 0 )
 BEGIN
	SET @sql_user_drop_statement = ''DROP USER '' + QUOTENAME(@terminate_user_name);
	EXECUTE (@sql_user_drop_statement);
	UPDATE #orphan_dependency SET is_terminated = 1 WHERE [database_name] = ''?'' AND [user_name] = @terminate_user_name;

	FETCH NEXT FROM @terminate_user_cursor INTO @terminate_user_name;
 END

CLOSE @terminate_user_cursor;
DEALLOCATE @terminate_user_cursor;
';

---Identify orphan users on this instance
EXEC sp_msforeachdb
    @command1 = @sql_collect_orphan
  , @command2 = @sql_collect_orphan_dependencies;

PRINT (@sql_terminate_orphan)

---Terminate orphan users on this instance
EXEC sp_msforeachdb @command1 = @sql_terminate_orphan;

---Report back found users as well as whether they 
---were terminated
SELECT * FROM #orphan_dependency ORDER BY [database_name];
GO