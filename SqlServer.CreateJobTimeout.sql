/*****************************************************************************
Job Timeout Table
*****************************************************************************/
USE [dba_maintenance];
GO
CREATE TABLE dbo.job_timeout (
    [job_name] sysname NOT NULL
  , [timeout_period_in_min] BIGINT NOT NULL
  , CONSTRAINT [pk_job_timeout] PRIMARY KEY (job_name)
)
INSERT INTO dbo.job_timeout (job_name, timeout_period_in_min) VALUES ('dba_index_optimization_user_databases_class_c', 360);
GO

/*****************************************************************************
Job Timeout Daemon

The following script evaluates an executing job against it's timeout. If a
timeout exists for a given job and the job has been running for as long or 
longer than it's allowed interval, it is stopped.
*****************************************************************************/
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET DEADLOCK_PRIORITY LOW;
SET XACT_ABORT ON;

DECLARE @timeout_db_is_primary bit = 0;
DECLARE @timeout_db_name sysname = 'dba_maintenance';

DECLARE @job_id AS uniqueidentifier;
DECLARE @job_name AS sysname;
DECLARE @log_message AS VARCHAR(2048);
DECLARE @execution_status AS bit;

IF EXISTS (SELECT * FROM sys.databases WHERE [name] = @timeout_db_name AND replica_id IS NOT NULL)
 BEGIN
	IF EXISTS (SELECT * FROM sys.dm_hadr_availability_replica_states ars RIGHT JOIN sys.databases dbs ON ars.replica_id = dbs.replica_id WHERE dbs.[name] = @timeout_db_name AND role_desc = 'PRIMARY')
		SET @timeout_db_is_primary = 1;
 END
ELSE 
	SET @timeout_db_is_primary = 1;

IF (@timeout_db_is_primary = 1)
 BEGIN
	IF (OBJECT_ID('tempdb..#active_jobs') IS NOT NULL)
		DROP TABLE #active_jobs;

	SELECT jact.job_id
         , job.[name] AS [job_name]
         , DATEDIFF(MINUTE, jact.start_execution_date, GETDATE()) AS [runtime_in_min]
	  INTO #active_jobs
	  FROM msdb.dbo.sysjobactivity jact LEFT JOIN msdb.dbo.sysjobhistory jhist
			ON jact.job_history_id = jhist.instance_id
		   INNER JOIN msdb.dbo.sysjobs job
			ON jact.job_id = job.job_id
	 WHERE jact.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)
	   AND start_execution_date IS NOT NULL
	   AND stop_execution_date IS NULL;

	DECLARE jobs_exceeding_timeout CURSOR fast_forward FOR
	 SELECT actv.job_id
		  , actv.job_name
	   FROM #active_jobs actv INNER JOIN dbo.job_timeout tout
			 ON actv.job_name = tout.job_name
	  WHERE tout.[timeout_period_in_min] <= actv.[runtime_in_min];

	 OPEN jobs_exceeding_timeout;

	FETCH NEXT FROM jobs_exceeding_timeout INTO @job_id, @job_name;

	WHILE @@FETCH_STATUS = 0 
	 BEGIN
		 EXECUTE @execution_status = msdb.dbo.sp_stop_job @job_id = @job_id;
	 
		 IF (@execution_status = 0)
		  BEGIN
			 SET @log_message = 'Execution of "' + @job_name + '" has exceeded timeout and has been terminated.'
			 EXECUTE xp_logevent  99999, @log_message, 'INFORMATIONAL';
		  END

		 FETCH NEXT FROM jobs_exceeding_timeout INTO @job_id, @job_name;
	 END

	CLOSE jobs_exceeding_timeout;
	DEALLOCATE jobs_exceeding_timeout;
 END
