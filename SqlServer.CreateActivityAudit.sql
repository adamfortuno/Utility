/********************************************************************
We are preparing to archive the "Sandbox" database on 
"s01-misc-dbs01". As part of that effort, we would like to 
identifying users or processes accessing that database. Please audit 
the database for activity.

IMPLEMENT ACTIVITY AUDIT on "Sandbox"

(1) Retrieve the name of the machine hosting the instance's by executing the 
    following on "s01-misc-dbs01":

    SELECT SERVERPROPERTIES('ComputerNamePhysicalNETBIOS');

(1) On the machine hosting the instance (retrieved from step-1), identify a 
    location (drive and path) to store audit files. The drive should have 
    at least 100 MB of capacity.
(2) Download the "create.audit.Sandbox.sql" attached to 
    this ticket.
(3) Update the "create.audit.Sandbox.sql" file by 
    setting the "<directory-path>" to the path to the directory selected 
    in step-1.
(4) Execute the modified script on "s01-misc-dbs01". This 
    will create the audit and related database audit spec.
********************************************************************/
USE [master]
GO
---Create the activity audit
CREATE SERVER AUDIT [measure_usage] TO FILE (
    FILEPATH = N'<directory-path>'
  , MAXSIZE = 5 MB
  , MAX_ROLLOVER_FILES = 200
  , RESERVE_DISK_SPACE = OFF
) WITH (
    QUEUE_DELAY = 1000
  , ON_FAILURE = CONTINUE
);
USE [Sandbox]
GO
CREATE DATABASE AUDIT SPECIFICATION [measure_database_usage] FOR SERVER AUDIT [measure_usage]
    ADD (DELETE ON DATABASE::[Sandbox] BY [public])
  , ADD (EXECUTE ON DATABASE::[Sandbox] BY [public])
  , ADD (INSERT ON DATABASE::[Sandbox] BY [public])
  , ADD (SELECT ON DATABASE::[Sandbox] BY [public])
  , ADD (UPDATE ON DATABASE::[Sandbox] BY [public])
WITH (STATE = ON);
GO

---Enable the activity audit
USE [Sandbox]
GO
ALTER DATABASE AUDIT SPECIFICATION [measure_database_usage] WITH (STATE = ON);
GO
USE [master];
GO
ALTER SERVER AUDIT [measure_usage] WITH (STATE = ON);
GO