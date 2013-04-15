/*******************************************************************************************************************************************************
**  Purpose: This script creates a dba database and all objects necessary to setup a database monitoring solution that notifies via email/texting. 
**			Historical data is kept for future trending/reporting.
**
**  Requirements: SQL Server 2005 and above. This script assumes you already have DBMail setup. It will create two new Operators which are used to populate the AlertSettings table.
**				These INSERTS will need to be modified if you are planning on using existing Operators already on your system.
**
**		*****MUST CHANGE*****
**
**		The TABLE INSERTS FOR DATABASESETTINGS MUST BE EDITED PRIOR TO RUNNING THIS SCRIPT (List of Databases)!!!
**		The TABLE INSERTS FOR DBMail OPERATORS MUST BE EDITED PRIOR TO RUNNING THIS SCRIPT (Email Addresses)!!!
**			**** SEARCH/REPLACE "CHANGEME" ****
**
**  
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  06/01/2011		Michael Rounds			1.0					Original Version
**  01/12/2012		Michael Rounds			1.1					Cleanup,many bugfixes  
**  01/17/2012		Michael Rounds			1.1.1				Replaced CURSORS with WHILE LOOPS
**	02/09/2012		Michael Rounds			1.2					New sections to the HealthReport; more compatibility bug fixes
**	02/16/2012		Michael Rounds			1.2.1				Added separate values for Email and Cell notifications; Display Server Uptime; bug fixes
**	02/20/2012		Michael Rounds			1.2.2				Fixed Blocking alert trigger bug when cell list is null
**	02/29/2012		Michael Rounds			1.3					Added CPU stats gathering and Alerting
**  08/31/2012		Michael Rounds			1.4					NVARCHAR now used everywhere. Updated HealthReport to be stand-alone
**	09/11/2012		Michael Rounds			1.4.1				Updated HealthReport, merged Long Running Jobs into Jobs section
**	11/05/2012		Michael Rounds			2.0					New database trigger, many HealthReport changes, small bug fixes, added data dictionary
**	11/27/2012		Michael Rounds			2.1					Tweaked Health Report to show certain elements even if there is no data (eg Trace flags)
**	12/17/2012		Michael Rounds			2.1.1				Changed usp_filestats and rpt_HealthReport so use new logic for gathering file stats (no longer using sysaltfiles)
**	12/27/2012		Michael Rounds			2.1.2				Fixed a bug in usp_filestats and rpt_healthreport gathering data on db's with different coallation
**	12/31/2012		Michael Rounds			2.2 				Added Deadlock section when trace flag 1222 is On.
**	01/07/2013		Michael Rounds			2.2.1				Fixed Divide by zero bug in file stats section
**	01/16/2013		Michael Rounds			2.2.2				Fixed a bug in usp_LongRunningJobs where the LongRunningJobs proc would show up in the alert
**	02/20/2013		Michael Rounds			2.2.3				Fixed a bug in the Deadlock section where some deadlocks weren't be included in the report
**	03/19/2013		Michael Rounds			2.3					Added new proc, usp_TodaysDeadlocks to display current days deadlocks (if tracelog 1222 is on)
**	04/07/2013		Michael Rounds			2.3.1				Expanded KBytesRead and KBytesWritten from NUMERIC 12,2 to 20,2 in table FileStatsHistory
**																Expanded lengths in temp table in usp_FileStats and rpt_HealthReport
**	04/11/2013		Michael Rounds			2.3.1				Changed Health Report to only show last 24 hours worth of File Stats instead of since server restart																
**	04/12/2013		Michael Rounds			2.3.2				Modified usp_MemoryUsageStats, usp_FileStats and rpt_HealthReport to be SQL Server 2012 compatible.
																Fixed bug in rpt_HealthReport - Changed #TEMPDATES from SELECT INTO - > CREATE, INSERT INTO
********************************************************************************************************************************************************
**
**		:::::CONTENTS:::::
**
**		:::OVERVIEW OF FEATURES:::
**		Blocking Alerts
**		Long Running Queries Alerts
**		Long Running Jobs Alers
**		Database Health Report
**		LDF and TempDB Monitoring and Alerts
**		Performance Statistics Gathering
**		CPU Stats and Alerts
**		Memory Usage Stats Gathering
**		Deadlock Reporting
**
**				:::::OBJECTS:::::
**
**				====MASTER DB:
**				==Procs:
**				dbo.sp_whoisactive == Author: Adam Machanic v11.11
**
**				====MSDB DB:
**				==Operators:
**					Email group
**					Cell(Text) group
**
**				==Job Category:
**					Database Monitoring
**
**				====DATABASE(S) TO MONITOR:
**				==Tables:
**				dbo.SchemaChangeLog
**				
**				==Triggers:
**				dbo.tr_DDL_SchemaChangeLog
**
**				====DBA DB:
**				==Tabes:
**				dbo.AlertSettings
**				dbo.DatabaseSettings
**				dbo.BlockingHistory
**				dbo.HealthReport
**				dbo.JobStatsHistory
**				dbo.FileStatsHistory
**				dbo.MemoryUsageHistory
**				dbo.PerfStatsHistory
**				dbo.QueryHistory
**				dbo.CPUStatsHistory
**				dbo.DataDictionary_Fields
**				dbo.DataDictionary_Tables
**
**				==Triggers:
**				ti_blockinghistory
**
**				==Procs:
**				dbo.usp_CheckBlocking
**				dbo.usp_CheckFiles
**				dbo.usp_FileStats (@InsertFlag BIT = 0)
**				dbo.usp_JobStats (@InsertFlag BIT = 0)
**				dbo.usp_LongRunningJobs
**				dbo.usp_LongRunningQueries
**				dbo.usp_MemoryUsageStats (@InsertFlag BIT = 0)
**				dbo.usp_PerfStats (@InsertFlag BIT = 0) == Autor: Unknown
**				dbo.usp_CPUStats
**				dbo.usp_CPUProcessAlert
**				dbo.rpt_Blocking (@DateRangeInDays INT)
**				dbo.rpt_HealthReport (@Recepients NVARCHAR(200) = NULL, @CC NVARCHAR(200) = NULL, @InsertFlag BIT = 0)
**				dbo.rpt_JobHistory (@JobName NVARCHAR(50), @DateRangeInDays INT)
**				dbo.rpt_Queries (@DateRangeInDays INT)
**				dbo.gen_GetHealthReportHTML (@DateStamp NVARCHAR(20))
**				dbo.gen_GetHealthReportToEmail (@DateStamp NVARCHAR(20))
**				dbo.gen_GetHealthReportToFile (@DateStamp NVARCHAR(20))
**				dbo.dd_ApplyDataDictionary
**				dbo.dd_PopulateDataDictionary
**				dbo.dd_ScavengeDataDictionaryFields
**				dbo.dd_ScavengeDataDictionaryTables
**				dbo.dd_TestDataDictionaryFields
**				dbo.dd_TestDataDictionaryTables
**				dbo.dd_UpdateDataDictionaryField
**				dbo.dd_UpdateDataDictionaryTable
**				dbo.sp_ViewTableExtendedProperties
**				dbo.usp_TodaysDeadlocks
**
**				==Jobs: (ALL JOBS DISABLED BY DEFAULT)
**				dba_BlockingAlert (DEFAULT Schedule: Runs every 15 seconds)
**				dba_CheckFiles (DEFAULT Schedule: Runs every 1 hour starting at 12:30am)
**				dba_HealthReport (DEFAULT Schedule: Runs every day at 6:05am)
**				dba_LongRunningJobsAlert (DEFAULT Schedule: Runs every 1 hour starting as 12:05am)
**				dba_LongRunningQueriesAlert (DEFAULT Schedule: Runs every 5 minutes Mon-Sat. SUNDAY Schedule is every 5 minutes from 7:02am - 5:01:59pm)
**				dba_MemoryUsageStats (DEFAULT Schedule: Runs every 15 minutes)
**				dba_PerfStats (DEFAULT Schedule: Runs every 5 minutes)
**				dba_CPUAlert (DEFAULT Schedule: Runs every 5 minutes)
**/
/*=======================================================================================================================
=============================================DBMAIL OPERATORS============================================================
=======================================================================================================================*/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA')
BEGIN
EXEC msdb.dbo.sp_add_operator @name=N'SQL_DBA', 
		@enabled=1,
		@email_address=N'matthew.monroe@pnnl.gov'
END
GO

IF NOT EXISTS (SELECT * FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA_vtext')
BEGIN
EXEC msdb.dbo.sp_add_operator @name=N'SQL_DBA_vtext', 
		@enabled=1,
		@email_address=N'matthew.monroe@pnnl.gov'
END
GO
/*=======================================================================================================================
=============================================DBA DB CREATE===============================================================
=======================================================================================================================*/
USE [master]
GO

IF NOT EXISTS (SELECT name FROM master..sysdatabases WHERE name = 'dba')
BEGIN
CREATE DATABASE [dba]

ALTER DATABASE [dba] SET RECOVERY SIMPLE
END
GO
/*========================================================================================================================
====================================================DBA TABLES============================================================
========================================================================================================================*/
USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DatabaseSettings' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE dbo.DatabaseSettings (
	[DBName] NVARCHAR(128) NOT NULL
		CONSTRAINT pk_DatabaseSettings
			PRIMARY KEY CLUSTERED ([DBName]),
	SchemaTracking BIT,
	LogFileAlerts BIT,
	LongQueryAlerts BIT,
	Reindex BIT
	)
	
INSERT INTO [dba].dbo.DatabaseSettings ([DBName], SchemaTracking, LogFileAlerts, LongQueryAlerts, Reindex)
SELECT name,1,1,1,1
FROM master..sysdatabases
WHERE [dbid] > 4

END
GO

USE [dba]
GO

IF EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DatabaseSettings' AND TABLE_SCHEMA = 'dbo')
BEGIN

-- Disable monitoring for select DBs
UPDATE [dba].dbo.DatabaseSettings
SET SchemaTracking = 0,
	LogFileAlerts = 0,
	LongQueryAlerts = 0,
	Reindex = 0
WHERE [DBName] Like 'DMS%t3' or 
      [DBName] Like 'DMS%Test' or
      [DBName] Like 'DMS%Beta' or

END
GO

USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AlertSettings' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE [dba].dbo.AlertSettings (
	Name NVARCHAR(50) NOT NULL
		CONSTRAINT pk_AlertSettings
			PRIMARY KEY CLUSTERED (Name),
	QueryValue INT,
	QueryValueDesc NVARCHAR(255),
	QueryValue2 NVARCHAR(255),
	QueryValue2Desc NVARCHAR(255),
	EmailList NVARCHAR(255),
	EmailList2 NVARCHAR(255),
	CellList NVARCHAR(255)
	)

INSERT INTO [dba].dbo.AlertSettings (Name,QueryValue,QueryValueDesc,QueryValue2,QueryValue2Desc,EmailList,CellList)
SELECT 'LongRunningJobs',60,'Seconds',NULL,NULL,(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA'),(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA_vtext') UNION ALL
SELECT 'LongRunningQueries',615,'Seconds',1200,'Seconds',(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA'),(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA_vtext') UNION ALL
SELECT 'BlockingAlert',10,'Seconds',20,'Seconds',(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA'),(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA_vtext') UNION ALL
SELECT 'LogFiles',50,'Percent',20,'Percent',(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA'),(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA_vtext') UNION ALL
SELECT 'TempDB',50,'Percent',20,'Percent',(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA'),(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA_vtext') UNION ALL
SELECT 'HealthReport',1,'NA',NULL,NULL,(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA'),NULL UNION ALL
SELECT 'CPUAlert',85,'Percent',95,'Percent',(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA'),(SELECT email_address FROM msdb.dbo.sysoperators WHERE name = 'SQL_DBA_vtext') 
END
GO

USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'JobStatsHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE [dba].dbo.JobStatsHistory (
	JobStatsHistoryId INT IDENTITY(1,1) NOT NULL
		CONSTRAINT pk_JobStatsHistory
			PRIMARY KEY CLUSTERED (JobStatsHistoryId),
	JobStatsID INT,
	JobStatsDateStamp DATETIME NOT NULL CONSTRAINT [DF_JobStatsHistory_JobStatsDateStamp] DEFAULT (GETDATE()),
	JobName NVARCHAR(255),
	Category NVARCHAR(255),
	[Enabled] INT,
	StartTime DATETIME,
	StopTime DATETIME,
	[AvgRunTime] NUMERIC(12,2),
	[LastRunTime] NUMERIC(12,2),
	RunTimeStatus NVARCHAR(30),
	LastRunOutcome NVARCHAR(20)
	)
END
GO

USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'QueryHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE [dba].dbo.QueryHistory (
	[QueryHistoryID] INT IDENTITY(1,1) NOT NULL
			CONSTRAINT pk_QueryHistory
				PRIMARY KEY CLUSTERED ([QueryHistoryID]),
	[Collection_Time] DATETIME NOT NULL,
	[Start_Time] DATETIME NOT NULL,
	[Login_Time] DATETIME NULL,
	[Session_ID] SMALLINT NOT NULL,
	[CPU] INT NULL,
	[Reads] BIGINT NULL,
	[Writes] BIGINT NULL,
	[Physical_Reads] BIGINT NULL,
	[Host_Name] NVARCHAR(128) NULL,
	[Database_Name] NVARCHAR(128) NULL,
	[Login_Name] NVARCHAR(128) NOT NULL,
	[SQL_Text] NVARCHAR(MAX) NULL,
	[Program_Name] NVARCHAR(128)
	)
END
GO

USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'BlockingHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE [dbo].[BlockingHistory](
	[BlockingHistoryID] INT IDENTITY(1,1) NOT NULL
		CONSTRAINT pk_BlockingHistory
			PRIMARY KEY CLUSTERED ([BlockingHistoryID]),	
	[DateStamp] DATETIME NOT NULL CONSTRAINT [DF_BlockingHistory_DateStamp]  DEFAULT (GETDATE()),
	Blocked_SPID SMALLINT NOT NULL,
	Blocking_SPID SMALLINT NOT NULL,
	Blocked_Login NVARCHAR(128) NOT NULL,
	Blocked_HostName NVARCHAR(128) NOT NULL,
	Blocked_WaitTime_Seconds NUMERIC(12, 2) NULL,
	Blocked_LastWaitType NVARCHAR(32) NOT NULL,
	Blocked_Status NVARCHAR(30) NOT NULL,
	Blocked_Program NVARCHAR(128) NOT NULL,
	Blocked_SQL_Text NVARCHAR(MAX) NULL,
	Offending_SPID SMALLINT NOT NULL,
	Offending_Login NVARCHAR(128) NOT NULL,
	Offending_NTUser NVARCHAR(128) NOT NULL,
	Offending_HostName NVARCHAR(128) NOT NULL,
	Offending_WaitType BIGINT NOT NULL,
	Offending_LastWaitType NVARCHAR(32) NOT NULL,
	Offending_Status NVARCHAR(30) NOT NULL,
	Offending_Program NVARCHAR(128) NOT NULL,
	Offending_SQL_Text NVARCHAR(MAX) NULL,
	[DBName] NVARCHAR(128) NULL
	)

END
GO

USE [dba]
GO

IF NOT EXISTS	(SELECT *
				FROM sys.triggers
				WHERE [name] = 'ti_blockinghistory')
BEGIN
	EXEC ('CREATE TRIGGER ti_blockinghistory ON BlockingHistory INSTEAD OF INSERT AS SELECT 1')
END
GO

ALTER TRIGGER [dbo].[ti_blockinghistory] ON [dbo].[BlockingHistory]
AFTER INSERT
AS 

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**	08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN
DECLARE @HTML NVARCHAR(MAX), @QueryValue INT, @QueryValue2 INT, @EmailList NVARCHAR(255), @CellList NVARCHAR(255), @ServerName NVARCHAR(50), @EmailSubject NVARCHAR(100)

SELECT @ServerName = CONVERT(NVARCHAR(50), SERVERPROPERTY('servername'))

SELECT @QueryValue = QueryValue,
		@QueryValue2 = QueryValue2,
		@EmailList = EmailList,
		@CellList = CellList 
FROM [dba].dbo.AlertSettings WHERE Name = 'BlockingAlert'

SELECT *
INTO #TEMP
FROM Inserted

IF EXISTS (SELECT * FROM #TEMP WHERE CAST(Blocked_WaitTime_Seconds AS DECIMAL) > @QueryValue)
BEGIN

SET	@HTML =
	'<html><head><style type="text/css">
	table { border: 0px; border-spacing: 0px; border-collapse: collapse;}
	th {color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;border: 0;}
	th.header {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;}
	td {font-size:11px; font-family:arial;border-right: 0;border-bottom: 1px solid #C1DAD7;padding: 5px 5px 5px 8px;}
	</style></head><body>
	<table width="1150"> <tr><th class="header" width="1150">Most Recent Blocking</th></tr></table>
	<table width="1150">
	<tr> 
	<th width="150">Date Stamp</th> 
	<th width="150">Database</th> 	
	<th width="60">Time(ss)</th> 
	<th width="60">Victim SPID</th>
	<th width="145">Victim Login</th>
	<th width="190">Victim SQL Text</th> 
	<th width="60">Blocking SPID</th> 	
	<th width="145">Blocking Login</th>
	<th width="190">Blocking SQL Text</th> 
	</tr>'

SELECT @HTML =  @HTML +   
	'<tr>
	<td width="150" bgcolor="#E0E0E0">' + CAST(DateStamp AS NVARCHAR) +'</td>
	<td width="130" bgcolor="#F0F0F0">' + [DBName] + '</td>
	<td width="60" bgcolor="#E0E0E0">' + CAST(Blocked_WaitTime_Seconds AS NVARCHAR) +'</td>
	<td width="60" bgcolor="#F0F0F0">' + CAST(Blocked_SPID AS NVARCHAR) +'</td>
	<td width="145" bgcolor="#E0E0E0">' + Blocked_Login +'</td>		
	<td width="200" bgcolor="#F0F0F0">' + REPLACE(REPLACE(REPLACE(LEFT(Blocked_SQL_Text,100),'CREATE',''),'TRIGGER',''),'PROCEDURE','') +'</td>
	<td width="60" bgcolor="#E0E0E0">' + CAST(Blocking_SPID AS NVARCHAR) +'</td>
	<td width="145" bgcolor="#F0F0F0">' + Offending_Login +'</td>
	<td width="200" bgcolor="#E0E0E0">' + REPLACE(REPLACE(REPLACE(LEFT(Offending_SQL_Text,100),'CREATE',''),'TRIGGER',''),'PROCEDURE','') +'</td>	
	</tr>'
FROM #TEMP
WHERE CAST(Blocked_WaitTime_Seconds AS DECIMAL) > @QueryValue

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'Blocking on ' + @ServerName + '!'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @EmailList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

END

IF @CellList IS NOT NULL
BEGIN
SELECT @EmailSubject = 'Blocking-' + @ServerName

IF @QueryValue2 IS NOT NULL
BEGIN
IF EXISTS (SELECT * FROM #TEMP WHERE CAST(BLOCKED_WAITTIME_SECONDS AS DECIMAL) > @QueryValue2)
BEGIN
SET	@HTML = '<html><head></head><body><table><tr><td>BlockingSPID,</td><td>Login,</td><td>Time</td></tr>'
SELECT @HTML =  @HTML +   
	'<tr><td>' + CAST(OFFENDING_SPID AS NVARCHAR) +',</td><td>' + LEFT(OFFENDING_LOGIN,7) +',</td><td>' + CAST(BLOCKED_WAITTIME_SECONDS AS NVARCHAR) +'</td></tr>'
FROM #TEMP
WHERE BLOCKED_WAITTIME_SECONDS > @QueryValue2
SELECT @HTML =  @HTML + '</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @CellList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'
END
END
END

IF @QueryValue2 IS NULL AND @CellList IS NOT NULL
BEGIN
/*TEXT MESSAGE*/
SET	@HTML = '<html><head></head><body><table><tr><td>BlockingSPID,</td><td>Login,</td><td>Time</td></tr>'
SELECT @HTML =  @HTML +   
	'<tr><td>' + CAST(OFFENDING_SPID AS NVARCHAR) +',</td><td>' + LEFT(OFFENDING_LOGIN,7) +',</td><td>' + CAST(BLOCKED_WAITTIME_SECONDS AS NVARCHAR) +'</td></tr>'
FROM #TEMP
WHERE BLOCKED_WAITTIME_SECONDS > @QueryValue
SELECT @HTML =  @HTML + '</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @CellList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'
END

DROP TABLE #TEMP
END
GO

USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FileStatsHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE dbo.FileStatsHistory (
	FileStatsHistoryID INT IDENTITY(1,1) NOT NULL
		CONSTRAINT pk_FileStatsHistory
			PRIMARY KEY CLUSTERED (FileStatsHistoryID),
	FileStatsID INT, 
	FileStatsDateStamp DATETIME NOT NULL CONSTRAINT DF_FileStatsHistory_DateStamp DEFAULT (GETDATE()),
		[DBName] NVARCHAR(128),
	[DBID] INT,
	[FileID] INT,
	[FileName] NVARCHAR(255),
	[LogicalFileName] NVARCHAR(255),
	[VLFCount] INT,
	DriveLetter NCHAR(1),
	FileMBSize NVARCHAR(30),
	[FileMaxSize] NVARCHAR(30),
	FileGrowth NVARCHAR(30),
	FileMBUsed NVARCHAR(30),
	FileMBEmpty NVARCHAR(30),
	FilePercentEmpty NUMERIC(12,2),
	LargeLDF INT,
	[FileGroup] NVARCHAR(100),
	NumberReads NVARCHAR(30),
	KBytesRead NUMERIC(20,2),
	NumberWrites NVARCHAR(30),
	KBytesWritten NUMERIC(20,2),
	IoStallReadMS NVARCHAR(30),
	IoStallWriteMS NVARCHAR(30),
	Cum_IO_GB NUMERIC(12,2),
	IO_Percent NUMERIC(12,2)
	)
END
GO

USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'HealthReport' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE [dba].dbo.HealthReport (
	HealthReportID INT IDENTITY(1,1) NOT NULL 
		CONSTRAINT PK_HealthReport
			PRIMARY KEY CLUSTERED (HealthReportID),
	DateStamp DATETIME NOT NULL CONSTRAINT [DF_HealthReport_datestamp] DEFAULT (GETDATE()),
	GeneratedHTML NVARCHAR(MAX)
	)
END
GO

USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'PerfStatsHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE [dbo].[PerfStatsHistory](
	[PerfStatsHistoryID] [INT] IDENTITY(1,1) NOT NULL
		CONSTRAINT PK_PerfStatsHistory
			PRIMARY KEY CLUSTERED (PerfStatsHistoryID),
	[BufferCacheHitRatio] NUMERIC(38, 13) NULL,
	[PageLifeExpectency] BIGINT NULL,
	[BatchRequestsPerSecond] BIGINT NULL,
	[CompilationsPerSecond] BIGINT NULL,
	[ReCompilationsPerSecond] BIGINT NULL,
	[UserConnections] BIGINT NULL,
	[LockWaitsPerSecond] BIGINT NULL,
	[PageSplitsPerSecond] BIGINT NULL,
	[ProcessesBlocked] BIGINT NULL,
	[CheckpointPagesPerSecond] BIGINT NULL,
	[StatDate] DATETIME NOT NULL
	)
END
GO

USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MemoryUsageHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE dbo.MemoryUsageHistory (
	MemoryUsageHistoryID INT IDENTITY(1,1) NOT NULL
		CONSTRAINT pk_MemoryUsageHistory
			PRIMARY KEY CLUSTERED (MemoryUsageHistoryID),
	DateStamp DATETIME NOT NULL CONSTRAINT [DF_MemoryUsageHistory_DateStamp] DEFAULT (GETDATE()),
	SystemPhysicalMemoryMB NVARCHAR(20),
	SystemVirtualMemoryMB NVARCHAR(20),
	DBUsageMB NVARCHAR(20),
	DBMemoryRequiredMB NVARCHAR(20),
	BufferCacheHitRatio NVARCHAR(20),
	BufferPageLifeExpectancy NVARCHAR(20),	
	BufferPoolCommitMB NVARCHAR(20),
	BufferPoolCommitTgtMB NVARCHAR(20),
	BufferPoolTotalPagesMB NVARCHAR(20),
	BufferPoolDataPagesMB NVARCHAR(20),
	BufferPoolFreePagesMB NVARCHAR(20),
	BufferPoolReservedPagesMB NVARCHAR(20),
	BufferPoolStolenPagesMB NVARCHAR(20),
	BufferPoolPlanCachePagesMB NVARCHAR(20),
	DynamicMemConnectionsMB NVARCHAR(20),
	DynamicMemLocksMB NVARCHAR(20),
	DynamicMemSQLCacheMB NVARCHAR(20),
	DynamicMemQueryOptimizeMB NVARCHAR(20),
	DynamicMemHashSortIndexMB NVARCHAR(20),
	CursorUsageMB NVARCHAR(20)
	)
END
GO

USE [dba]
GO

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CPUStatsHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
CREATE TABLE dbo.CPUStatsHistory (
	CPUStatsHistoryID INT IDENTITY NOT NULL
			CONSTRAINT [PK_CPUStatsHistory]
				PRIMARY KEY CLUSTERED (CPUStatsHistoryID),
	SQLProcessPercent INT,
	SystemIdleProcessPercent INT,
	OtherProcessPerecnt INT,
	DateStamp DATETIME
	)
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='DataDictionary_Tables')
BEGIN
CREATE TABLE dbo.DataDictionary_Tables(
	SchemaName SYSNAME NOT NULL,
	TableName SYSNAME NOT NULL,
	TableDescription VARCHAR(4000) NOT NULL
		CONSTRAINT DF_DataDictionary_TableDescription DEFAULT (''),
		CONSTRAINT PK_DataDictionary_Tables 
			PRIMARY KEY CLUSTERED (SchemaName,TableName)
	)
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='DataDictionary_Fields')
BEGIN
CREATE TABLE dbo.DataDictionary_Fields(
	SchemaName SYSNAME NOT NULL,
	TableName SYSNAME NOT NULL,
	FieldName SYSNAME NOT NULL,
	FieldDescription VARCHAR(4000) NOT NULL
		CONSTRAINT DF_DataDictionary_FieldDescription DEFAULT (''),
		CONSTRAINT PK_DataDictionary_Fields 
			PRIMARY KEY CLUSTERED (SchemaName,TableName,FieldName)
)
END
GO
/*========================================================================================================================
====================================================DBA INDEXES===========================================================
========================================================================================================================*/
IF NOT EXISTS (SELECT name FROM SYSINDEXES WHERE NAME = 'IDX_JobStatHistory_JobStatsID_INC')
BEGIN
CREATE INDEX IDX_JobStatHistory_JobStatsID_INC
	ON [dba].[dbo].[JobStatsHistory] ([JobStatsID]) INCLUDE ([JobStatsHistoryId])
END
GO

IF NOT EXISTS (SELECT name FROM SYSINDEXES WHERE NAME = 'IDX_JobStatHistory_JobStatsID_Status_RunTime_INC')
BEGIN
CREATE INDEX IDX_JobStatHistory_JobStatsID_Status_RunTime_INC 
	ON [dba].[dbo].[JobStatsHistory] ([JobStatsID], [RunTimeStatus],[LastRunTime]) INCLUDE ([StopTime])
END
GO

IF NOT EXISTS (SELECT name FROM SYSINDEXES WHERE NAME = 'IDX_JobStatHistory_JobStatsID_Status_RunTime')
BEGIN
CREATE INDEX IDX_JobStatHistory_JobStatsID_Status_RunTime 
	ON [dba].[dbo].[JobStatsHistory] ([JobStatsID], [RunTimeStatus],[LastRunTime])
END
GO
/*========================================================================================================================
===========================================SCHEMA CHANGE TRACKING TABLE AND TRIGGER=======================================
========================================================================================================================*/
DECLARE @DBName NVARCHAR(128)

CREATE TABLE #TEMP ([DBName] NVARCHAR(128), [Status] INT)

INSERT INTO #TEMP ([DBName], [Status])
SELECT [DBName], 0
FROM [dba].dbo.DatabaseSettings WHERE SchemaTracking = 1 AND [DBName] NOT LIKE 'AdventureWorks%'

SET @DBName = (SELECT TOP 1 [DBName] FROM #TEMP WHERE [Status] = 0)

WHILE @DBName IS NOT NULL
BEGIN

DECLARE @SQL NVARCHAR(MAX)

SET @SQL = 
'USE ' + '[' + @DBName + ']' +';

IF NOT EXISTS (SELECT *	FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''SchemaChangeLog'' AND TABLE_SCHEMA = ''dbo'')
BEGIN
CREATE TABLE [dbo].[SchemaChangeLog](
	[SchemaChangeLogID] INT IDENTITY(1,1) NOT NULL
		CONSTRAINT PK_SchemaChangeLog
			PRIMARY KEY CLUSTERED (SchemaChangeLogID),	
	[CreateDate] DATETIME NULL,
	[LoginName] SYSNAME NULL,
	[ComputerName] SYSNAME NULL,
	[DBName] SYSNAME NOT NULL,
	[SQLEvent] SYSNAME NOT NULL,
	[Schema] SYSNAME NULL,
	[ObjectName] SYSNAME NULL,
	[SQLCmd] NVARCHAR(MAX) NOT NULL,
	[XmlEvent] XML NOT NULL
	)
END;

DECLARE @triggersql1 NVARCHAR(MAX)

SET @triggersql1 = ''IF NOT EXISTS (SELECT *
				FROM sys.triggers
				WHERE [name] = ''''tr_DDL_SchemaChangeLog'''')
BEGIN
	EXEC (''''CREATE TRIGGER tr_DDL_SchemaChangeLog ON DATABASE FOR CREATE_TABLE AS SELECT 1'''')
END;''

EXEC(@triggersql1)

DECLARE @triggersql2 NVARCHAR(MAX)

SET @triggersql2 = ''ALTER TRIGGER [tr_DDL_SchemaChangeLog] ON DATABASE 
FOR DDL_DATABASE_LEVEL_EVENTS AS 

    SET NOCOUNT ON

    DECLARE @data XML
    DECLARE @schema SYSNAME
    DECLARE @object SYSNAME
    DECLARE @eventType SYSNAME

    SET @data = EVENTDATA()
    SET @eventType = @data.value(''''(/EVENT_INSTANCE/EventType)[1]'''', ''''SYSNAME'''')
    SET @schema = @data.value(''''(/EVENT_INSTANCE/SchemaName)[1]'''', ''''SYSNAME'''')
    SET @object = @data.value(''''(/EVENT_INSTANCE/ObjectName)[1]'''', ''''SYSNAME'''') 

    INSERT [dbo].[SchemaChangeLog] 
        (
        [CreateDate],
        [LoginName], 
        [ComputerName],
        [DBName],
        [SQLEvent], 
        [Schema], 
        [ObjectName], 
        [SQLCmd], 
        [XmlEvent]
        ) 
    SELECT
        GETDATE(),
        SUSER_NAME(), 
		HOST_NAME(),   
        @data.value(''''(/EVENT_INSTANCE/DatabaseName)[1]'''', ''''SYSNAME''''),
        @eventType, 
        @schema, 
        @object, 
        @data.value(''''(/EVENT_INSTANCE/TSQLCommand)[1]'''', ''''NVARCHAR(MAX)''''), 
        @data
;''

EXEC(@triggersql2)
'

EXEC(@SQL)

UPDATE #TEMP
SET [Status] = 1
WHERE [DBName] = @DBName

SET @DBName = (SELECT TOP 1 [DBName] FROM #TEMP WHERE [Status] = 0)

END

DROP TABLE #TEMP
GO
/*========================================================================================================================
======================================================DBA PROCS===========================================================
========================================================================================================================*/
USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_JobStats' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_JobStats AS SELECT 1')
END
GO

ALTER PROC [dbo].[usp_JobStats] (@InsertFlag BIT = 0)
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0				Comments creation
**  03/13/2012		Michael Rounds			1.1				Added join to syscategories to pull in Category name
***************************************************************************************************************/

BEGIN

SELECT sj.job_id, 
		sj.name,
		sc.name AS Category,
		sj.[Enabled], 
		sjs.last_run_outcome,
        (SELECT MAX(run_date) 
			FROM msdb..sysjobhistory(nolock) sjh 
			WHERE sjh.job_id = sj.job_id) AS last_run_date
INTO #TEMP
FROM msdb..sysjobs(nolock) sj
JOIN msdb..sysjobservers(nolock) sjs
    ON sjs.job_id = sj.job_id
JOIN msdb..syscategories sc
	ON sj.category_id = sc.category_id	

SELECT
	t.name AS JobName,
	t.Category,
	t.[Enabled],
	MAX(ja.start_execution_date) AS [StartTime],
	MAX(ja.stop_execution_date) AS [StopTime],
	COALESCE(AvgRunTime,0) AS AvgRunTime,
	CASE 
		WHEN ja.stop_execution_date IS NULL THEN DATEDIFF(ss,ja.start_execution_date,GETDATE())
		ELSE DATEDIFF(ss,ja.start_execution_date,ja.stop_execution_date) END AS [LastRunTime],
	CASE 
			WHEN ja.stop_execution_date IS NULL AND ja.start_execution_date IS NOT NULL THEN
				CASE WHEN DATEDIFF(ss,ja.start_execution_date,GETDATE())
					> (AvgRunTime + AvgRunTime * .25) THEN 'LongRunning-NOW'				
				ELSE 'NormalRunning-NOW'
				END
			WHEN DATEDIFF(ss,ja.start_execution_date,ja.stop_execution_date) 
				> (AvgRunTime + AvgRunTime * .25) THEN 'LongRunning-History'
			WHEN ja.stop_execution_date IS NULL AND ja.start_execution_date IS NULL THEN 'NA'
			ELSE 'NormalRunning-History'
	END AS [RunTimeStatus],	
	CASE
		WHEN ja.stop_execution_date IS NULL AND ja.start_execution_date IS NOT NULL THEN 'InProcess'
		WHEN ja.stop_execution_date IS NOT NULL AND t.last_run_outcome = 3 THEN 'CANCELLED'
		WHEN ja.stop_execution_date IS NOT NULL AND t.last_run_outcome = 0 THEN 'ERROR'			
		WHEN ja.stop_execution_date IS NOT NULL AND t.last_run_outcome = 1 THEN 'SUCCESS'			
		ELSE 'NA'
	END AS [LastRunOutcome]
INTO #TEMP2
FROM #TEMP AS t
LEFT OUTER
JOIN (SELECT MAX(session_id) as session_id,job_id FROM msdb.dbo.sysjobactivity(nolock) WHERE run_requested_date IS NOT NULL GROUP BY job_id) AS ja2
	ON t.job_id = ja2.job_id
LEFT OUTER
JOIN msdb.dbo.sysjobactivity(nolock) ja
	ON ja.session_id = ja2.session_id and ja.job_id = t.job_id
LEFT OUTER 
JOIN (SELECT job_id,
			AVG	((run_duration/10000 * 3600) + ((run_duration%10000)/100*60) + (run_duration%10000)%100) + 	STDEV ((run_duration/10000 * 3600) + ((run_duration%10000)/100*60) + (run_duration%10000)%100) AS [AvgRuntime]
		FROM msdb..sysjobhistory(nolock)
		WHERE step_id = 0 AND run_status = 1 and run_duration >= 0
		GROUP BY job_id) art 
	ON t.job_id = art.job_id
GROUP BY t.name,t.Category,t.[Enabled],t.last_run_outcome,ja.start_execution_date,ja.stop_execution_date,AvgRunTime
ORDER BY t.name

SELECT * FROM #TEMP2

IF @InsertFlag = 1
BEGIN

INSERT INTO [dba].dbo.JobStatsHistory (JobName,Category,[Enabled],StartTime,StopTime,[AvgRunTime],[LastRunTime],RunTimeStatus,LastRunOutcome) 
SELECT JobName,Category,[Enabled],StartTime,StopTime,[AvgRunTime],[LastRunTime],RunTimeStatus,LastRunOutcome
FROM #TEMP2

UPDATE [dba].dbo.JobStatsHistory
SET JobStatsID = (SELECT COALESCE(MAX(JobStatsID),0) + 1 FROM [dba].dbo.JobStatsHistory)
WHERE JobStatsID IS NULL

END
DROP TABLE #TEMP
DROP TABLE #TEMP2
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_PerfStats' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_PerfStats AS SELECT 1')
END
GO

ALTER PROC dbo.usp_PerfStats (@InsertFlag BIT = 0)
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**	08/31/2012		Michael Rounds			1.1					Changed to use temp tables, Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN
SET NOCOUNT ON
 
DECLARE @BatchRequestsPerSecond BIGINT, 
		@CompilationsPerSecond BIGINT, 
		@ReCompilationsPerSecond BIGINT, 
		@LockWaitsPerSecond BIGINT, 
		@PageSplitsPerSecond BIGINT, 
		@CheckpointPagesPerSecond BIGINT, 
		@stat_date DATETIME,
		@PerfStatsID INT

CREATE TABLE #RatioStatsX (
	[object_name] NVARCHAR(128),
    [counter_name] NVARCHAR(128),
    [instance_name] NVARCHAR(128),
    [cntr_value] BIGINT,
    [cntr_type] INT
    )

CREATE TABLE #RatioStatsY (
    [object_name] NVARCHAR(128),
    [counter_name] NVARCHAR(128),
    [instance_name] NVARCHAR(128),
    [cntr_value] BIGINT,
    [cntr_type] INT
    )

SET @stat_date = GETDATE();
 
INSERT INTO #RatioStatsX ([object_name],[counter_name],[instance_name],[cntr_value],[cntr_type])
SELECT [object_name],[counter_name],[instance_name],[cntr_value],[cntr_type] 
FROM sys.dm_os_performance_counters;
 
SELECT TOP 1 @BatchRequestsPerSecond = cntr_value
FROM #RatioStatsX
WHERE counter_name = 'Batch Requests/sec'
AND object_name LIKE '%SQL Statistics%';

SELECT TOP 1 @CompilationsPerSecond = cntr_value
FROM #RatioStatsX
WHERE counter_name = 'SQL Compilations/sec'
AND object_name LIKE '%SQL Statistics%';

SELECT TOP 1 @ReCompilationsPerSecond = cntr_value
FROM #RatioStatsX
WHERE counter_name = 'SQL Re-Compilations/sec'
AND object_name LIKE '%SQL Statistics%';

SELECT TOP 1 @LockWaitsPerSecond = cntr_value
FROM #RatioStatsX
WHERE counter_name = 'Lock Waits/sec'
AND instance_name = '_Total'
AND object_name LIKE '%Locks%';

SELECT TOP 1 @PageSplitsPerSecond = cntr_value
FROM #RatioStatsX
WHERE counter_name = 'Page Splits/sec'
AND object_name LIKE '%Access Methods%'; 

SELECT TOP 1 @CheckpointPagesPerSecond = cntr_value
FROM #RatioStatsX
WHERE counter_name = 'Checkpoint Pages/sec'
AND object_name LIKE '%Buffer Manager%';                                         
 
WAITFOR DELAY '00:00:01'

INSERT INTO #RatioStatsY ([object_name],[counter_name],[instance_name],[cntr_value],[cntr_type])
SELECT [object_name],[counter_name],[instance_name],[cntr_value],[cntr_type]
FROM sys.dm_os_performance_counters

SELECT (a.cntr_value * 1.0 / b.cntr_value) * 100.0 [BufferCacheHitRatio],
	c.cntr_value  AS [PageLifeExpectency],
	d.[BatchRequestsPerSecond],
	e.[CompilationsPerSecond],
	f.[ReCompilationsPerSecond],
	g.cntr_value AS [UserConnections],
	h.LockWaitsPerSecond,
	i.PageSplitsPerSecond,
	j.cntr_value AS [ProcessesBlocked],
	k.CheckpointPagesPerSecond,
	GETDATE() AS StatDate                           
INTO #TEMP
FROM (SELECT * FROM #RatioStatsY
               WHERE counter_name = 'Buffer cache hit ratio'
               AND object_name LIKE '%Buffer Manager%') a  
     CROSS JOIN  
      (SELECT * FROM #RatioStatsY
                WHERE counter_name = 'Buffer cache hit ratio base'
                AND object_name LIKE '%Buffer Manager%') b    
     CROSS JOIN
      (SELECT * FROM #RatioStatsY
                WHERE counter_name = 'Page life expectancy '
                AND object_name LIKE '%Buffer Manager%') c
     CROSS JOIN
     (SELECT (cntr_value - @BatchRequestsPerSecond) /
                     (CASE WHEN DATEDIFF(ss,@stat_date, GETDATE()) = 0
                           THEN  1
                           ELSE DATEDIFF(ss,@stat_date, GETDATE()) END) AS [BatchRequestsPerSecond]
                FROM #RatioStatsY
                WHERE counter_name = 'Batch Requests/sec'
                AND object_name LIKE '%SQL Statistics%') d   
     CROSS JOIN
     (SELECT (cntr_value - @CompilationsPerSecond) /
                     (CASE WHEN DATEDIFF(ss,@stat_date, GETDATE()) = 0
                           THEN  1
                           ELSE DATEDIFF(ss,@stat_date, GETDATE()) END) AS [CompilationsPerSecond]
                FROM #RatioStatsY
                WHERE counter_name = 'SQL Compilations/sec'
                AND object_name LIKE '%SQL Statistics%') e 
     CROSS JOIN
     (SELECT (cntr_value - @ReCompilationsPerSecond) /
                     (CASE WHEN DATEDIFF(ss,@stat_date, GETDATE()) = 0
                           THEN  1
                           ELSE DATEDIFF(ss,@stat_date, GETDATE()) END) AS [ReCompilationsPerSecond]
                FROM #RatioStatsY
                WHERE counter_name = 'SQL Re-Compilations/sec'
                AND object_name LIKE '%SQL Statistics%') f
     CROSS JOIN
     (SELECT * FROM #RatioStatsY
               WHERE counter_name = 'User Connections'
               AND object_name LIKE '%General Statistics%') g
     CROSS JOIN
     (SELECT (cntr_value - @LockWaitsPerSecond) /
                     (CASE WHEN DATEDIFF(ss,@stat_date, GETDATE()) = 0
                           THEN  1
                           ELSE DATEDIFF(ss,@stat_date, GETDATE()) END) AS [LockWaitsPerSecond]
                FROM #RatioStatsY
                WHERE counter_name = 'Lock Waits/sec'
                AND instance_name = '_Total'
                AND object_name LIKE '%Locks%') h
     CROSS JOIN
     (SELECT (cntr_value - @PageSplitsPerSecond) /
                     (CASE WHEN DATEDIFF(ss,@stat_date, GETDATE()) = 0
                           THEN  1
                           ELSE DATEDIFF(ss,@stat_date, GETDATE()) END) AS [PageSplitsPerSecond]
                FROM #RatioStatsY
                WHERE counter_name = 'Page Splits/sec'
                AND object_name LIKE '%Access Methods%') i
     CROSS JOIN
     (SELECT * FROM #RatioStatsY
               WHERE counter_name = 'Processes blocked'
               AND object_name LIKE '%General Statistics%') j
     CROSS JOIN
     (SELECT (cntr_value - @CheckpointPagesPerSecond) /
                     (CASE WHEN DATEDIFF(ss,@stat_date, GETDATE()) = 0
                           THEN  1
                           ELSE DATEDIFF(ss,@stat_date, GETDATE()) END) AS [CheckpointPagesPerSecond]
                FROM #RatioStatsY
                WHERE counter_name = 'Checkpoint Pages/sec'
                AND object_name LIKE '%Buffer Manager%') k
                
DROP TABLE #RatioStatsX
DROP TABLE #RatioStatsY
SELECT * FROM #TEMP

IF @InsertFlag = 1
BEGIN
INSERT INTO [dba].dbo.PerfStatsHistory (BufferCacheHitRatio, PageLifeExpectency, BatchRequestsPerSecond, CompilationsPerSecond, ReCompilationsPerSecond, UserConnections, LockWaitsPerSecond, PageSplitsPerSecond, ProcessesBlocked, CheckpointPagesPerSecond, StatDate)
SELECT BufferCacheHitRatio, PageLifeExpectency, BatchRequestsPerSecond, CompilationsPerSecond, ReCompilationsPerSecond, UserConnections, LockWaitsPerSecond, PageSplitsPerSecond, ProcessesBlocked, CheckpointPagesPerSecond, StatDate
FROM #TEMP
END
DROP TABLE #TEMP
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_MemoryUsageStats' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_MemoryUsageStats AS SELECT 1')
END
GO

ALTER PROC dbo.usp_MemoryUsageStats (@InsertFlag BIT = 0)
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**	08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
**	04/12/2013		Michael Rounds			1.2					Added SQL Server 2012 compatibility - column differences in sys.dm_os_sys_info
***************************************************************************************************************/

BEGIN

SET NOCOUNT ON 

DECLARE @pg_size INT, @Instancename NVARCHAR(50), @MemoryUsageHistoryID INT, @SQLVer NVARCHAR(20)

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'

SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

CREATE TABLE #TEMP (
	DateStamp DATETIME NOT NULL CONSTRAINT [DF_TEMP_TEMP] DEFAULT (GETDATE()),
	SystemPhysicalMemoryMB NVARCHAR(20),
	SystemVirtualMemoryMB NVARCHAR(20),
	DBUsageMB NVARCHAR(20),
	DBMemoryRequiredMB NVARCHAR(20),
	BufferCacheHitRatio NVARCHAR(20),
	BufferPageLifeExpectancy NVARCHAR(20),	
	BufferPoolCommitMB NVARCHAR(20),
	BufferPoolCommitTgtMB NVARCHAR(20),
	BufferPoolTotalPagesMB NVARCHAR(20),
	BufferPoolDataPagesMB NVARCHAR(20),
	BufferPoolFreePagesMB NVARCHAR(20),
	BufferPoolReservedPagesMB NVARCHAR(20),
	BufferPoolStolenPagesMB NVARCHAR(20),
	BufferPoolPlanCachePagesMB NVARCHAR(20),
	DynamicMemConnectionsMB NVARCHAR(20),
	DynamicMemLocksMB NVARCHAR(20),
	DynamicMemSQLCacheMB NVARCHAR(20),
	DynamicMemQueryOptimizeMB NVARCHAR(20),
	DynamicMemHashSortIndexMB NVARCHAR(20),
	CursorUsageMB NVARCHAR(20)
	)

SELECT @SQLVer = LEFT(CONVERT(NVARCHAR(20),SERVERPROPERTY('productversion')),4)

IF CAST(@SQLVer AS NUMERIC(4,2)) < 11
BEGIN
-- (SQL 2008R2 And Below)
EXEC sp_executesql
	N'INSERT INTO #TEMP (SystemPhysicalMemoryMB, SystemVirtualMemoryMB, BufferPoolCommitMB, BufferPoolCommitTgtMB)
	SELECT physical_memory_in_bytes/1048576.0 as [SystemPhysicalMemoryMB],
		 virtual_memory_in_bytes/1048576.0 as [SystemVirtualMemoryMB],
		 (bpool_committed*8)/1024.0 as [BufferPoolCommitMB],
		 (bpool_commit_target*8)/1024.0 as [BufferPoolCommitTgtMB]
	FROM sys.dm_os_sys_info'	
END
ELSE BEGIN
-- (SQL 2012 And Above)
EXEC sp_executesql
	N'INSERT INTO #TEMP (SystemPhysicalMemoryMB, SystemVirtualMemoryMB, BufferPoolCommitMB, BufferPoolCommitTgtMB)
	SELECT physical_memory_kb/1024.0 as [SystemPhysicalMemoryMB],
		virtual_memory_kb/1024.0 as [SystemVirtualMemoryMB],
		(committed_kb)/1024.0 as [BufferPoolCommitMB],
		(committed_target_kb)/1024.0 as [BufferPoolCommitTgtMB]
FROM sys.dm_os_sys_info'
END

UPDATE #TEMP
SET [DBUsageMB] = (cntr_value/1024.0)
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Total Server Memory (KB)'

UPDATE #TEMP
SET [DBMemoryRequiredMB] = (cntr_value/1024.0)
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Target Server Memory (KB)'

UPDATE #TEMP
SET [BufferPoolTotalPagesMB] = ((cntr_value*@pg_size)/1048576.0)
FROM sys.dm_os_performance_counters
WHERE object_name= @Instancename+'Buffer Manager' and counter_name = 'Total pages' 

UPDATE #TEMP
SET [BufferPoolDataPagesMB] = ((cntr_value*@pg_size)/1048576.0)
FROM sys.dm_os_performance_counters
WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Database pages' 

UPDATE #TEMP
SET [BufferPoolFreePagesMB] = ((cntr_value*@pg_size)/1048576.0)
FROM sys.dm_os_performance_counters
WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Free pages'

UPDATE #TEMP
SET [BufferPoolReservedPagesMB] = ((cntr_value*@pg_size)/1048576.0)
FROM sys.dm_os_performance_counters
WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Reserved pages'

UPDATE #TEMP
SET [BufferPoolStolenPagesMB] = ((cntr_value*@pg_size)/1048576.0)
FROM sys.dm_os_performance_counters
WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Stolen pages'

UPDATE #TEMP
SET [BufferPoolPlanCachePagesMB] = ((cntr_value*@pg_size)/1048576.0)
FROM sys.dm_os_performance_counters
WHERE object_name=@Instancename+'Plan Cache' and counter_name = 'Cache Pages'  and instance_name = '_Total'

UPDATE #TEMP
SET [DynamicMemConnectionsMB] = (cntr_value/1024.0)
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Connection Memory (KB)'

UPDATE #TEMP
SET [DynamicMemLocksMB] = (cntr_value/1024.0)
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Lock Memory (KB)'

UPDATE #TEMP
SET [DynamicMemSQLCacheMB] = (cntr_value/1024.0)
FROM sys.dm_os_performance_counters
WHERE counter_name = 'SQL Cache Memory (KB)'

UPDATE #TEMP
SET [DynamicMemQueryOptimizeMB] = (cntr_value/1024.0)
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Optimizer Memory (KB) '

UPDATE #TEMP
SET [DynamicMemHashSortIndexMB] = (cntr_value/1024.0)
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Granted Workspace Memory (KB) '

UPDATE #TEMP
SET [CursorUsageMB] = (cntr_value/1024.0)
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Cursor memory usage' and instance_name = '_Total'

UPDATE #TEMP
SET [BufferCacheHitRatio] = (a.cntr_value * 1.0 / b.cntr_value) * 100.0
FROM sys.dm_os_performance_counters  a
JOIN  (SELECT cntr_value,OBJECT_NAME 
		FROM sys.dm_os_performance_counters  
		WHERE counter_name = 'Buffer cache hit ratio base'
		AND OBJECT_NAME = 'SQLServer:Buffer Manager') b 
ON  a.OBJECT_NAME = b.OBJECT_NAME
WHERE a.counter_name = 'Buffer cache hit ratio'
AND a.OBJECT_NAME = 'SQLServer:Buffer Manager'

UPDATE #TEMP
SET [BufferPageLifeExpectancy] = cntr_value
FROM sys.dm_os_performance_counters  
WHERE counter_name = 'Page life expectancy'
AND OBJECT_NAME = 'SQLServer:Buffer Manager'

SELECT SystemPhysicalMemoryMB, SystemVirtualMemoryMB, DBUsageMB, DBMemoryRequiredMB, BufferCacheHitRatio, BufferPageLifeExpectancy, BufferPoolCommitMB, BufferPoolCommitTgtMB, BufferPoolTotalPagesMB, BufferPoolDataPagesMB, BufferPoolFreePagesMB, BufferPoolReservedPagesMB, BufferPoolStolenPagesMB, BufferPoolPlanCachePagesMB, DynamicMemConnectionsMB, DynamicMemLocksMB, DynamicMemSQLCacheMB, DynamicMemQueryOptimizeMB, DynamicMemHashSortIndexMB, CursorUsageMB FROM #TEMP

IF @InsertFlag = 1
BEGIN

INSERT INTO [dba].dbo.MemoryUsageHistory (SystemPhysicalMemoryMB, SystemVirtualMemoryMB, DBUsageMB, DBMemoryRequiredMB, BufferCacheHitRatio, BufferPageLifeExpectancy, BufferPoolCommitMB, BufferPoolCommitTgtMB, BufferPoolTotalPagesMB, BufferPoolDataPagesMB, BufferPoolFreePagesMB, BufferPoolReservedPagesMB, BufferPoolStolenPagesMB, BufferPoolPlanCachePagesMB, DynamicMemConnectionsMB, DynamicMemLocksMB, DynamicMemSQLCacheMB, DynamicMemQueryOptimizeMB, DynamicMemHashSortIndexMB, CursorUsageMB)
SELECT SystemPhysicalMemoryMB, SystemVirtualMemoryMB, DBUsageMB, DBMemoryRequiredMB, BufferCacheHitRatio, BufferPageLifeExpectancy, BufferPoolCommitMB, BufferPoolCommitTgtMB, BufferPoolTotalPagesMB, BufferPoolDataPagesMB, BufferPoolFreePagesMB, BufferPoolReservedPagesMB, BufferPoolStolenPagesMB, BufferPoolPlanCachePagesMB, DynamicMemConnectionsMB, DynamicMemLocksMB, DynamicMemSQLCacheMB, DynamicMemQueryOptimizeMB, DynamicMemHashSortIndexMB, CursorUsageMB
FROM #TEMP
END

DROP TABLE #TEMP
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_CPUStats' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_CPUStats AS SELECT 1')
END
GO

ALTER PROC dbo.usp_CPUStats
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/28/2012		Michael Rounds			1.0					New Proc to gather CPU stats
**	08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN
SET NOCOUNT ON

DECLARE @ts_now BIGINT, @ts_now2 BIGINT, @SQLVer NVARCHAR(20), @sql NVARCHAR(MAX) 

CREATE TABLE #TEMP (
	[SQLProcessPercent] INT,
	[SystemIdleProcessPercent] INT,
	[OtherProcessPerecnt] INT,
	DateStamp DATETIME
	)

SELECT @SQLVer = LEFT(CONVERT(NVARCHAR(20),SERVERPROPERTY('productversion')),4)

IF CAST(@SQLVer AS NUMERIC(4,2)) < 10
BEGIN
EXEC sp_executesql
	N'SELECT @ts_now = cpu_ticks / CONVERT(float, cpu_ticks_in_ms) FROM sys.dm_os_sys_info',
	N'@ts_now BIGINT OUTPUT',
	@ts_now = @ts_now2 OUTPUT

	INSERT INTO #TEMP ([SQLProcessPercent],[SystemIdleProcessPercent],[OtherProcessPerecnt],DateStamp)
    SELECT SQLProcessUtilization AS [SQLProcessPercent],
                   SystemIdle AS [SystemIdleProcessPercent],
                   100 - SystemIdle - SQLProcessUtilization AS [OtherProcessPerecnt],
                   DATEADD(ms, -1 * (@ts_now2 - [timestamp]), GETDATE()) AS [DateStamp]
    FROM (
          SELECT record.value('(./Record/@id)[1]', 'int') AS record_id,
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int')
                AS [SystemIdle],
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]',
                'int')
                AS [SQLProcessUtilization], [timestamp]
          FROM (
                SELECT [timestamp], CONVERT(xml, record) AS [record]
                FROM sys.dm_os_ring_buffers
                WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                AND record LIKE '%<SystemHealth>%') AS x
          ) AS y
    ORDER BY record_id DESC
END
ELSE BEGIN
-- Get CPU Utilization History (SQL 2008 Only)
    SELECT @ts_now = cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info
	INSERT INTO #TEMP ([SQLProcessPercent],[SystemIdleProcessPercent],[OtherProcessPerecnt],DateStamp)
    SELECT SQLProcessUtilization AS [SQLProcessPercent],
                   SystemIdle AS [SystemIdleProcessPercent],
                   100 - SystemIdle - SQLProcessUtilization AS [OtherProcessPerecnt],
                   DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [DateStamp]
    FROM (
          SELECT record.value('(./Record/@id)[1]', 'int') AS record_id,
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int')
                AS [SystemIdle],
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]',
                'int')
                AS [SQLProcessUtilization], [timestamp]
          FROM (
                SELECT [timestamp], convert(xml, record) AS [record]
                FROM sys.dm_os_ring_buffers
                WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                AND record LIKE '%<SystemHealth>%') AS x
          ) AS y
    ORDER BY record_id DESC
END

SELECT * FROM #TEMP

DROP TABLE #TEMP
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_CPUProcessAlert' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_CPUProcessAlert AS SELECT 1')
END
GO

ALTER PROC dbo.usp_CPUProcessAlert
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/29/2012		Michael Rounds			1.0					New Proc to alert on CPU usage
**	08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN
SET NOCOUNT ON

DECLARE @QueryValue INT, @QueryValue2 INT, @EmailList NVARCHAR(255), @CellList NVARCHAR(255), @HTML NVARCHAR(MAX), @ServerName NVARCHAR(50), @EmailSubject NVARCHAR(100), @LastDateStamp DATETIME

SELECT @LastDateStamp = MAX(DateStamp) FROM [dba].dbo.CPUStatsHistory

SELECT @ServerName = CONVERT(NVARCHAR(50), SERVERPROPERTY('servername'))

SELECT @QueryValue = QueryValue,
	@QueryValue2 = QueryValue2,
	@EmailList = EmailList,
	@CellList = CellList	
FROM [dba].dbo.AlertSettings WHERE Name = 'CPUAlert'

CREATE TABLE #TEMP (
	[SQLProcessPercent] INT,
	[SystemIdleProcessPercent] INT,
	[OtherProcessPerecnt] INT,
	DateStamp DATETIME
	)

INSERT INTO #TEMP
EXEC [dba].dbo.usp_CPUStats

IF EXISTS (SELECT * FROM #TEMP WHERE SQLProcessPercent > @QueryValue AND DateStamp > COALESCE(@LastDateStamp, GETDATE() -1))
BEGIN
SET	@HTML =
	'<html><head><style type="text/css">
	table { border: 0px; border-spacing: 0px; border-collapse: collapse;}
	th {color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;border: 0;}
	th.header {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;}
	td {font-size:11px; font-family:arial;border-right: 0;border-bottom: 1px solid #C1DAD7;padding: 5px 5px 5px 8px;}
	</style></head><body>
	<table width="700"> <tr><th class="header" width="700">High CPU Alert</th></tr></table>	
	<table width="700">
	<tr>  
	<th width="150">SQL Percent</th>	
	<th width="150">System Idle Percent</th>  
	<th width="150">Other Process Percent</th>  
	<th width="200">Date Stamp</th>
	</tr>'
SELECT @HTML =  @HTML +   
	'<tr>
	<td bgcolor="#E0E0E0" width="150">' + CAST(SQLProcessPercent AS NVARCHAR) +'</td>
	<td bgcolor="#F0F0F0" width="150">' + CAST(SystemIdleProcessPercent AS NVARCHAR) +'</td>
	<td bgcolor="#E0E0E0" width="150">' + CAST(OtherProcessPerecnt AS NVARCHAR) +'</td>
	<td bgcolor="#F0F0F0" width="200">' + CAST(DateStamp AS NVARCHAR) +'</td>	
	</tr>'
FROM #TEMP WHERE SQLProcessPercent > @QueryValue AND DateStamp > COALESCE(@LastDateStamp, GETDATE() -1)

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'High CPU Alert on ' + @ServerName + '!'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @EmailList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

IF @CellList IS NOT NULL
BEGIN

/*TEXT MESSAGE*/
IF EXISTS (SELECT * FROM #TEMP WHERE SQLProcessPercent > COALESCE(@QueryValue2, @QueryValue))
BEGIN
	SET	@HTML =
		'<html><head></head><body><table><tr><td>CPU,</td><td>Idle,</td><td>Other,</td><td>Date</td></tr>'
	SELECT @HTML =  @HTML +   
		'<tr><td>' + CAST(SQLProcessPercent AS NVARCHAR) +',</td><td>' + CAST(SystemIdleProcessPercent AS NVARCHAR) +',</td><td>' + CAST(OtherProcessPerecnt AS NVARCHAR) +',</td><td>' + CAST(DateStamp AS NVARCHAR) + '</td></tr>'
	FROM #TEMP WHERE SQLProcessPercent > COALESCE(@QueryValue2, @QueryValue)

	SELECT @HTML =  @HTML + '</table></body></html>'

	SELECT @EmailSubject = 'HighCPUAlert-' + @ServerName

	EXEC msdb.dbo.sp_send_dbmail
	@recipients= @CellList,
	@subject = @EmailSubject,
	@body = @HTML,
	@body_format = 'HTML'

END
END
END

INSERT INTO [dba].dbo.CPUStatsHistory ([SQLProcessPercent],[SystemIdleProcessPercent],[OtherProcessPerecnt],DateStamp)
SELECT [SQLProcessPercent],[SystemIdleProcessPercent],[OtherProcessPerecnt],DateStamp
FROM #TEMP
WHERE CONVERT(DATETIME, DateStamp, 120) > CONVERT(DATETIME,COALESCE(@LastDateStamp, GETDATE() -1), 120)
ORDER BY DATESTAMP ASC

DROP TABLE #TEMP
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_LongRunningJobs' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_LongRunningJobs AS SELECT 1')
END
GO

ALTER PROC [dbo].[usp_LongRunningJobs]
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**	08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
**	01/16/2013		Michael Rounds			1.2					Added "AND JobName <> 'dba_LongRunningJobsAlert'" to INSERT into TEMP table
***************************************************************************************************************/

BEGIN

EXEC [dba].dbo.usp_JobStats @InsertFlag=1

DECLARE @JobStatsID INT, @QueryValue INT, @QueryValue2 INT, @EmailList NVARCHAR(255), @CellList NVARCHAR(255), @HTML NVARCHAR(MAX), @ServerName NVARCHAR(50), @EmailSubject NVARCHAR(100)

SELECT @ServerName = CONVERT(NVARCHAR(50), SERVERPROPERTY('servername'))

SET @JobStatsID = (SELECT MAX(JobStatsID) FROM [dba].dbo.JobStatsHistory)
SELECT @QueryValue = QueryValue,
	@QueryValue2 = QueryValue2,
	@EmailList = EmailList,
	@CellList = CellList	
FROM [dba].dbo.AlertSettings WHERE Name = 'LongRunningJobs'

CREATE TABLE #TEMP (
	JobStatsHistoryID INT,
	JobStatsID INT,
	JobStatsDateStamp DATETIME,
	JobName NVARCHAR(255),
	[Enabled] INT,
	StartTime DATETIME,
	StopTime DATETIME,
	AvgRunTime NUMERIC(12,2),
	LastRunTime NUMERIC(12,2),
	RunTimeStatus NVARCHAR(30),
	LastRunOutcome NVARCHAR(20)
	)

INSERT INTO #TEMP (JobStatsHistoryId, JobStatsID, JobStatsDateStamp, JobName, [Enabled], StartTime, StopTime, AvgRunTime, LastRunTime, RunTimeStatus, LastRunOutcome)
SELECT JobStatsHistoryId, JobStatsID, JobStatsDateStamp, JobName, [Enabled], StartTime, StopTime, AvgRunTime, LastRunTime, RunTimeStatus, LastRunOutcome
FROM [dba].dbo.JobStatsHistory
WHERE RunTimeStatus = 'LongRunning-NOW'
AND JobName <> 'dba_LongRunningJobsAlert'
AND LastRunTime > @QueryValue AND JobStatsID = @JobStatsID

IF EXISTS (SELECT * FROM #TEMP)
BEGIN
SET	@HTML =
	'<html><head><style type="text/css">
	table { border: 0px; border-spacing: 0px; border-collapse: collapse;}
	th {color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;border: 0;}
	th.header {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;}
	td {font-size:11px; font-family:arial;border-right: 0;border-bottom: 1px solid #C1DAD7;padding: 5px 5px 5px 8px;}
	</style></head><body>
	<table width="725"> <tr><th class="header" width="725">Long Running Jobs</th></tr></table>	
	<table width="725">
	<tr>  
	<th width="250">JobName</th>	
	<th width="100">AvgRunTime</th>  
	<th width="100">LastRunTime</th>  
	<th width="150">RunTimeStatus</th>  	
	<th width="125">LastRunOutcome</th>
	</tr>'
SELECT @HTML =  @HTML +   
	'<tr>
	<td bgcolor="#E0E0E0" width="250">' + JobName +'</td>
	<td bgcolor="#E0E0E0" width="100">' + COALESCE(CAST(AvgRunTime AS NVARCHAR), '') +'</td>
	<td bgcolor="#F0F0F0" width="100">' + CAST(LastRunTime AS NVARCHAR) +'</td>
	<td bgcolor="#E0E0E0" width="150">' + RunTimeStatus +'</td>	
	<td bgcolor="#F0F0F0" width="125">' + LastRunOutcome +'</td>		
	</tr>'
FROM #TEMP

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'ACTIVE Long Running JOBS on ' + @ServerName + '! - IMMEDIATE Action Required'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @EmailList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

IF @CellList IS NOT NULL
BEGIN

IF @QueryValue2 IS NOT NULL
BEGIN
TRUNCATE TABLE #TEMP
INSERT INTO #TEMP (JobStatsHistoryId, JobStatsID, JobStatsDateStamp, JobName, [Enabled], StartTime, StopTime, AvgRunTime, LastRunTime, RunTimeStatus, LastRunOutcome)
SELECT JobStatsHistoryId, JobStatsID, JobStatsDateStamp, JobName, [Enabled], StartTime, StopTime, AvgRunTime, LastRunTime, RunTimeStatus, LastRunOutcome
FROM [dba].dbo.JobStatsHistory
WHERE RunTimeStatus = 'LongRunning-NOW'
AND JobName <> 'dba_LongRunningJobsAlert'
AND LastRunTime > @QueryValue2 AND JobStatsID = @JobStatsID
END

/*TEXT MESSAGE*/
IF EXISTS (SELECT * FROM #TEMP)
BEGIN
	SET	@HTML =
		'<html><head></head><body><table><tr><td>Name,</td><td>AvgRun,</td><td>LastRun</td></tr>'
	SELECT @HTML =  @HTML +   
		'<tr><td>' + COALESCE(CAST(LOWER(LEFT(JobName,17)) AS NVARCHAR), '') +',</td><td>' + COALESCE(CAST(AvgRunTime AS NVARCHAR), '') +',</td><td>' + COALESCE(CAST(LastRunTime AS NVARCHAR), '') +'</td></tr>'
	FROM #TEMP

	SELECT @HTML =  @HTML + '</table></body></html>'

	SELECT @EmailSubject = 'JobsPastDue-' + @ServerName

	EXEC msdb.dbo.sp_send_dbmail
	@recipients= @CellList,
	@subject = @EmailSubject,
	@body = @HTML,
	@body_format = 'HTML'

END
END
DROP TABLE #TEMP
END
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_LongRunningQueries' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_LongRunningQueries AS SELECT 1')
END
GO

ALTER PROC dbo.usp_LongRunningQueries
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**	08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN

EXEC master..sp_WhoIsActive
        @format_output = 0,
        @output_column_list = '[Collection_Time][Start_Time][Login_Time][Session_ID][CPU][Reads][Writes][Physical_Reads][Host_Name][Database_Name][Login_Name][SQL_Text][Program_Name]',
        @destination_table = '[dba].dbo.QueryHistory'       

DECLARE @QueryValue INT, @QueryValue2 INT, @EmailList NVARCHAR(255), @CellList NVARCHAR(255), @ServerName NVARCHAR(50), @EmailSubject NVARCHAR(100)

SELECT @ServerName = CONVERT(NVARCHAR(50), SERVERPROPERTY('servername'))

SELECT @QueryValue = QueryValue,
	@QueryValue2 = QueryValue2,
	@EmailList = EmailList,
	@CellList = CellList
FROM [dba].dbo.AlertSettings WHERE Name = 'LongRunningQueries'

DECLARE @LastQueryHistoryID INT, @LastCollectionTime DATETIME

SELECT @LastQueryHistoryID =  MIN(a.queryhistoryID) -1
FROM [dba].dbo.queryhistory a
WHERE a.collection_time = (SELECT MAX(collection_time) FROM [dba].dbo.QueryHistory WHERE collection_time > GETDATE() -1) 

SELECT @LastCollectionTime = Collection_Time FROM [dba].dbo.QueryHistory WHERE QueryHistoryID = @LastQueryHistoryID

CREATE TABLE #TEMP (
	QueryHistoryID INT,
	Collection_time DATETIME,
	Start_Time DATETIME,
	Login_Time DATETIME,
	Session_ID SMALLINT,
	CPU INT,
	Reads BIGINT,
	Writes BIGINT,
	Physical_reads BIGINT,
	[Host_Name] NVARCHAR(128),
	[DBName] NVARCHAR(128),
	Login_name NVARCHAR(128),
	SQL_Text NVARCHAR(MAX),
	[Program_name] NVARCHAR(128)
	)

INSERT INTO #TEMP (QueryHistoryID, collection_time, start_time, login_time, session_id, CPU, reads, writes, physical_reads, [host_name], [DBName], login_name, sql_text, [program_name])
SELECT QueryHistoryID, collection_time, start_time, login_time, session_id, CPU, reads, writes, physical_reads, [host_name], [Database_Name], login_name, sql_text, [program_name]
FROM [dba].dbo.QueryHistory 
WHERE (DATEDIFF(ss,start_time,collection_time)) >= @QueryValue
AND (DATEDIFF(mi,collection_time,GETDATE())) < (DATEDIFF(mi,@LastCollectionTime, collection_time))
AND [Database_Name] NOT IN (SELECT [DBName] FROM [dba].dbo.DatabaseSettings WHERE LongQueryAlerts = 0)
AND sql_text NOT LIKE 'BACKUP DATABASE%'
AND sql_text NOT LIKE 'RESTORE VERIFYONLY%'
AND sql_text NOT LIKE 'ALTER INDEX%'
AND sql_text NOT LIKE 'DECLARE @BlobEater%'
AND sql_text NOT LIKE 'DBCC%'
AND sql_text NOT LIKE 'WAITFOR(RECEIVE%'

IF EXISTS (SELECT * FROM #TEMP)
BEGIN

DECLARE @HTML NVARCHAR(MAX)

SET	@HTML =
	'<html><head><style type="text/css">
	table { border: 0px; border-spacing: 0px; border-collapse: collapse;}
	th {color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;border: 0;}
	th.header {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;}
	td {font-size:11px; font-family:arial;border-right: 0;border-bottom: 1px solid #C1DAD7;padding: 5px 5px 5px 8px;}
	</style></head><body>
	<table width="900"> <tr><th class="header" width="900">Long Running Queries</th></tr></table>
	<table width="900">
	<tr>  
	<th width="100">DateStamp</th>
	<th width="100">ElapsedTime(ss)</th>
	<th width="50">SPID</th>
	<th width="75">Database</th>
	<th width="100">Login</th> 	
	<th width="475">QueryText</th>
	</tr>'
SELECT @HTML =  @HTML +   
	'<tr>
	<td bgcolor="#E0E0E0" width="100">' + CAST(collection_time AS NVARCHAR) +'</td>	
	<td bgcolor="#F0F0F0" width="100">' + CAST(DATEDIFF(ss,start_time,collection_time) AS NVARCHAR) +'</td>
	<td bgcolor="#E0E0E0" width="50">' + CAST(Session_id AS NVARCHAR) +'</td>
	<td bgcolor="#F0F0F0" width="75">' + CAST([DBName] AS NVARCHAR) +'</td>	
	<td bgcolor="#E0E0E0" width="100">' + CAST(login_name AS NVARCHAR) +'</td>	
	<td bgcolor="#F0F0F0" width="475">' + LEFT(sql_text,100) +'</td>			
	</tr>'
FROM #TEMP

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'Long Running QUERIES on ' + @ServerName + '!'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @EmailList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

IF @CellList IS NOT NULL
BEGIN

IF @QueryValue2 IS NOT NULL
BEGIN
TRUNCATE TABLE #TEMP
INSERT INTO #TEMP (QueryHistoryID, collection_time, start_time, login_time, session_id, CPU, reads, writes, physical_reads, [host_name], [DBName], login_name, sql_text, [program_name])
SELECT QueryHistoryID, collection_time, start_time, login_time, session_id, CPU, reads, writes, physical_reads, [host_name], [Database_Name], login_name, sql_text, [program_name]
FROM [dba].dbo.QueryHistory 
WHERE (DATEDIFF(ss,start_time,collection_time)) >= @QueryValue2
AND (DATEDIFF(mi,collection_time,GETDATE())) < (DATEDIFF(mi,@LastCollectionTime, collection_time))
AND [Database_Name] NOT IN (SELECT [DBName] FROM [dba].dbo.DatabaseSettings WHERE LongQueryAlerts = 0)
AND sql_text NOT LIKE 'BACKUP DATABASE%'
AND sql_text NOT LIKE 'RESTORE VERIFYONLY%'
AND sql_text NOT LIKE 'ALTER INDEX%'
AND sql_text NOT LIKE 'DECLARE @BlobEater%'
AND sql_text NOT LIKE 'DBCC%'
AND sql_text NOT LIKE 'WAITFOR(RECEIVE%'
END

/*TEXT MESSAGE*/
IF EXISTS (SELECT * FROM #TEMP)
BEGIN
SET	@HTML =
	'<html><head></head><body><table><tr><td>Time,</td><td>SPID,</td><td>Login</td></tr>'
SELECT @HTML =  @HTML +   
	'<tr><td>' + CAST(DATEDIFF(ss,start_time,collection_time) AS NVARCHAR) +',</td><td>' + CAST(Session_id AS NVARCHAR) +',</td><td>' + CAST(login_name AS NVARCHAR) +'</td></tr>'
FROM #TEMP

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'LongQueries-' + @ServerName

EXEC msdb.dbo.sp_send_dbmail
@recipients= @CellList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

END
END
DROP TABLE #TEMP
END
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_CheckBlocking' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_CheckBlocking AS SELECT 1')
END
GO

ALTER PROCEDURE [dbo].[usp_CheckBlocking] 
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**	08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN
SET NOCOUNT ON
 
IF EXISTS (SELECT * FROM master..sysprocesses WHERE spid > 50 AND blocked != 0 AND ((CAST(waittime AS DECIMAL) /1000) > 0))
BEGIN

INSERT INTO [dba].dbo.BlockingHistory (Blocked_SPID, Blocking_SPID, Blocked_Login, Blocked_HostName, Blocked_WaitTime_Seconds, Blocked_LastWaitType, Blocked_Status, 
	Blocked_Program, Blocked_SQL_Text, Offending_SPID, Offending_Login, Offending_NTUser, Offending_HostName, Offending_WaitType, Offending_LastWaitType, Offending_Status, 
	Offending_Program, Offending_SQL_Text, [DBName])

SELECT
a.spid AS Blocked_SPID,
a.blocked AS Blocking_SPID,
a.loginame AS Blocked_Login,
a.hostname AS Blocked_HostName,
(CAST(a.waittime AS DECIMAL) /1000) AS Blocked_WaitTime_Seconds,
a.lastwaittype AS Blocked_LastWaitType,
a.[status] AS Blocked_Status,
a.[program_name] AS Blocked_Program,
CAST(st1.[text] AS NVARCHAR(MAX)) as Blocked_SQL_Text,
b.spid AS Offending_SPID,
b.loginame AS Offending_Login,
b.nt_username AS Offending_NTUser,
b.hostname AS Offending_HostName,
b.waittime AS Offending_WaitType,
b.lastwaittype AS Offending_LastWaitType,
b.[status] AS Offending_Status,
b.[program_name] AS Offending_Program,
CAST(st2.text AS NVARCHAR(MAX)) as Offending_SQL_Text,
(SELECT name from master..sysdatabases WHERE [dbid] = a.[dbid]) AS [DBName]
FROM master..sysprocesses as a CROSS APPLY sys.dm_exec_sql_text (a.sql_handle) as st1
JOIN master..sysprocesses as b CROSS APPLY sys.dm_exec_sql_text (b.sql_handle) as st2
ON a.blocked = b.spid
WHERE a.spid > 50 AND a.blocked != 0 AND ((CAST(a.waittime AS DECIMAL) /1000) > 0)

END
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_FileStats' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_FileStats AS SELECT 1')
END
GO

ALTER PROC [dbo].[usp_FileStats] (@InsertFlag BIT = 0)
AS
/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**  06/10/2012		Michael Rounds			1.1					Updated to use new FileStatsHistory table
**	08/31/2012		Michael Rounds			1.2					Changed VARCHAR to NVARCHAR
**	11/05/2012		Michael Rounds			2.0					Rewrote to use sysaltfiles instead of looping through sysfiles, gathering more data now too
**  12/17/2012		Michael Rounds			2.1					Apparently sysaltfiles is not good to use, went back to sysfiles, but still using new data gathering method
**	12/27/2012		Michael Rounds			2.1.2				Fixed a bug in gathering data on db's with different coallation
**	01/07/2012		Michael Rounds			2.1.3				Fixed Divide by zero bug
**	04/07/2013		Michael Rounds			2.1.4				Extended the lengths of KBytesRead and KBytesWritte in temp table FILESTATS - NUMERIC(12,2) to (20,2)
**	04/12/2013		Michael Rounds			2.1.5				Added SQL Server 2012 compatibility
***************************************************************************************************************/

BEGIN

CREATE TABLE #FILESTATS (
	[DBName] NVARCHAR(128),
	[DBID] INT,
	[FileID] INT,	
	[FileName] NVARCHAR(255),
	[LogicalFileName] NVARCHAR(255),
	[VLFCount] INT,
	DriveLetter NCHAR(1),
	FileMBSize NVARCHAR(30),
	[FileMaxSize] NVARCHAR(30),
	FileGrowth NVARCHAR(30),
	FileMBUsed NVARCHAR(30),
	FileMBEmpty NVARCHAR(30),
	FilePercentEmpty NUMERIC(12,2),
	LargeLDF INT,
	[FileGroup] NVARCHAR(100),
	NumberReads NVARCHAR(30),
	KBytesRead NUMERIC(20,2),
	NumberWrites NVARCHAR(30),
	KBytesWritten NUMERIC(20,2),
	IoStallReadMS NVARCHAR(30),
	IoStallWriteMS NVARCHAR(30),
	Cum_IO_GB NUMERIC(12,2),
	IO_Percent NUMERIC(12,2)
	)

CREATE TABLE #LOGSPACE (
	[DBName] NVARCHAR(128) NOT NULL,
	[LogSize] NUMERIC(12,2) NOT NULL,
	[LogPercentUsed] NUMERIC(12,2) NOT NULL,
	[LogStatus] INT NOT NULL
	)

CREATE TABLE #DATASPACE (
	[DBName] NVARCHAR(128) NULL,
	[Fileid] INT NOT NULL,
	[FileGroup] INT NOT NULL,
	[TotalExtents] NUMERIC(12,2) NOT NULL,
	[UsedExtents] NUMERIC(12,2) NOT NULL,
	[FileLogicalName] NVARCHAR(128) NULL,
	[Filename] NVARCHAR(255) NOT NULL
	)

CREATE TABLE #TMP_DB (
	[DBName] NVARCHAR(128)
	) 

DECLARE @SQL NVARCHAR(MAX), @DBName NVARCHAR(128), @SQLVer NVARCHAR(20)

SELECT @SQLVer = LEFT(CONVERT(NVARCHAR(20),SERVERPROPERTY('productversion')),4)

SET @SQL = 'DBCC SQLPERF (LOGSPACE) WITH NO_INFOMSGS' 

INSERT INTO #LOGSPACE ([DBName],LogSize,LogPercentUsed,LogStatus)
EXEC(@SQL)

CREATE INDEX IDX_tLogSpace_Database ON #LOGSPACE ([DBName])

INSERT INTO #TMP_DB 
SELECT LTRIM(RTRIM(name)) AS [DBName]
FROM master..sysdatabases 
WHERE category IN ('0', '1','16')
AND DATABASEPROPERTYEX(name,'STATUS')='ONLINE'
ORDER BY name

CREATE INDEX IDX_TMPDB_Database ON #TMP_DB ([DBName])

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB)

WHILE @DBName IS NOT NULL 
BEGIN

SET @SQL = 'USE ' + '[' +@DBName + ']' + '
DBCC SHOWFILESTATS WITH NO_INFOMSGS'

INSERT INTO #DATASPACE ([Fileid],[FileGroup],[TotalExtents],[UsedExtents],[FileLogicalName],[Filename])
EXEC (@SQL)

UPDATE #DATASPACE
SET [DBName] = @DBName
WHERE COALESCE([DBName],'') = ''

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB WHERE [DBName] > @DBName)

END

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB)

WHILE @DBName IS NOT NULL 
BEGIN
 
SET @SQL = 'USE ' + '[' +@DBName + ']' + '
INSERT INTO #FILESTATS (
	[DBName],
	[DBID],
	[FileID],	
	[DriveLetter],
	[Filename],
	[LogicalFileName],
	[Filegroup],
	[FileMBSize],
	[FileMaxSize],
	[FileGrowth],
	[FileMBUsed],
	[FileMBEmpty],
	[FilePercentEmpty])
SELECT	DBName = ''' + '[' + @dbname + ']' + ''',
		DB_ID() AS [DBID],
		SF.FileID AS [FileID],
		LEFT(SF.[FileName], 1) AS DriveLetter,		
		LTRIM(RTRIM(REVERSE(SUBSTRING(REVERSE(SF.[Filename]),0,CHARINDEX(''\'',REVERSE(SF.[Filename]),0))))) AS [Filename],
		SF.name AS LogicalFileName,
		COALESCE(filegroup_name(SF.groupid),'''') AS [Filegroup],
		CAST((SF.size * 8)/1024 AS NVARCHAR) AS [FileMBSize], 
		CASE SF.maxsize 
			WHEN -1 THEN N''Unlimited'' 
			ELSE CONVERT(NVARCHAR(15), (CAST(SF.maxsize AS BIGINT) * 8)/1024) + N'' MB'' 
			END AS FileMaxSize, 
		(CASE WHEN SF.[status] & 0x100000 = 0 THEN CONVERT(NVARCHAR,CEILING((growth * 8192)/(1024.0*1024.0))) + '' MB''
			ELSE CONVERT (NVARCHAR, growth) + '' %'' 
			END) AS FileGrowth,
		CAST(COALESCE(((DSP.UsedExtents * 64.00) / 1024), LSP.LogSize *(LSP.LogPercentUsed/100)) AS BIGINT) AS [FileMBUsed],
		(SF.size * 8)/1024 - CAST(COALESCE(((DSP.UsedExtents * 64.00) / 1024), LSP.LogSize *(LSP.LogPercentUsed/100)) AS BIGINT) AS [FileMBEmpty],
		(CAST(((SF.size * 8)/1024 - CAST(COALESCE(((DSP.UsedExtents * 64.00) / 1024), LSP.LogSize *(LSP.LogPercentUsed/100)) AS BIGINT)) AS DECIMAL) / 
			CAST(CASE WHEN COALESCE((SF.size * 8)/1024,0) = 0 THEN 1 ELSE (SF.size * 8)/1024 END AS DECIMAL)) * 100 AS [FilePercentEmpty]			
FROM sys.sysfiles SF
JOIN master..sysdatabases SDB
	ON db_id() = SDB.[dbid]
JOIN sys.dm_io_virtual_file_stats(NULL,NULL) b
	ON db_id() = b.[database_id] AND SF.fileid = b.[file_id]
LEFT OUTER 
JOIN #DATASPACE DSP
	ON DSP.[Filename] COLLATE DATABASE_DEFAULT = SF.[Filename] COLLATE DATABASE_DEFAULT
LEFT OUTER 
JOIN #LOGSPACE LSP
	ON LSP.[DBName] = SDB.Name
GROUP BY SDB.Name,SF.FileID,SF.[FileName],SF.name,SF.groupid,SF.size,SF.maxsize,SF.[status],growth,DSP.UsedExtents,LSP.LogSize,LSP.LogPercentUsed'

EXEC(@SQL)

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB WHERE [DBName] > @DBName)
END

DROP TABLE #LOGSPACE
DROP TABLE #DATASPACE

UPDATE f
SET f.NumberReads = b.num_of_reads,
	f.KBytesRead = b.num_of_bytes_read / 1024,
	f.NumberWrites = b.num_of_writes,
	f.KBytesWritten = b.num_of_bytes_written / 1024,
	f.IoStallReadMS = b.io_stall_read_ms,
	f.IoStallWriteMS = b.io_stall_write_ms,
	f.Cum_IO_GB = b.CumIOGB,
	f.IO_Percent = b.IOPercent
FROM #FILESTATS f
JOIN (SELECT database_ID, [file_id], num_of_reads, num_of_bytes_read, num_of_writes, num_of_bytes_written, io_stall_read_ms, io_stall_write_ms, 
			CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576 AS DECIMAL(12, 2)) / 1024 AS CumIOGB,
			CAST(CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576 AS DECIMAL(12,2)) / 1024 / 
				SUM(CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576 AS DECIMAL(12, 2)) / 1024) OVER() * 100 AS DECIMAL(5, 2)) AS IOPercent
		FROM sys.dm_io_virtual_file_stats(NULL,NULL)
		GROUP BY database_id, [file_id],num_of_reads, num_of_bytes_read, num_of_writes, num_of_bytes_written, io_stall_read_ms, io_stall_write_ms) AS b
ON f.[DBID] = b.[database_id] AND f.fileid = b.[file_id]

UPDATE b
SET b.LargeLDF = 
	CASE WHEN CAST(b.FileMBSize AS INT) > CAST(a.FileMBSize AS INT) THEN 1
	ELSE 2 
	END
FROM #FILESTATS a
JOIN #FILESTATS b
ON a.[DBName] = b.[DBName] 
AND a.[FileName] LIKE '%mdf' 
AND b.[FileName] LIKE '%ldf'

/* VLF INFO - USES SAME TMP_DB TO GATHER STATS */
CREATE TABLE #VLFINFO (
	[DBName] NVARCHAR(128) NULL,
	RecoveryUnitId NVARCHAR(3),
	FileID NVARCHAR(3), 
	FileSize NUMERIC(20,0),
	StartOffset BIGINT, 
	FSeqNo BIGINT, 
	[Status] CHAR(1),
	Parity NVARCHAR(4),
	CreateLSN NUMERIC(25,0)
	)

IF CAST(@SQLVer AS NUMERIC(4,2)) < 11
BEGIN
-- (SQL 2008R2 And Below)
SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB)

WHILE @DBName IS NOT NULL 
BEGIN

SET @SQL = 'USE ' + '[' +@DBName + ']' + '
INSERT INTO #VLFINFO (FileID,FileSize,StartOffset,FSeqNo,[Status],Parity,CreateLSN)
EXEC(''DBCC LOGINFO WITH NO_INFOMSGS'');'
EXEC(@SQL)

SET @SQL = 'UPDATE #VLFINFO SET DBName = ''' +@DBName+ ''' WHERE DBName IS NULL;'
EXEC(@SQL)

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB WHERE [DBName] > @DBName)
END
END
ELSE BEGIN
-- (SQL 2012 And Above)
SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB)

WHILE @DBName IS NOT NULL 
BEGIN
 
SET @SQL = 'USE ' + '[' +@DBName + ']' + '
INSERT INTO #VLFINFO (RecoveryUnitID, FileID,FileSize,StartOffset,FSeqNo,[Status],Parity,CreateLSN)
EXEC(''DBCC LOGINFO WITH NO_INFOMSGS'');'
EXEC(@SQL)

SET @SQL = 'UPDATE #VLFINFO SET DBName = ''' +@DBName+ ''' WHERE DBName IS NULL;'
EXEC(@SQL)

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB WHERE [DBName] > @DBName)
END
END

DROP TABLE #TMP_DB

UPDATE a
SET a.VLFCount = (SELECT COUNT(1) FROM #VLFINFO WHERE [DBName] = REPLACE(REPLACE(a.DBName,'[',''),']',''))
FROM #FILESTATS a
WHERE COALESCE(a.[FileGroup],'') = ''

DROP TABLE #VLFINFO

SELECT * FROM #FILESTATS

IF @InsertFlag = 1
BEGIN

DECLARE @FileStatsID INT

SELECT @FileStatsID = COALESCE(MAX(FileStatsID),0) + 1 FROM [dba].dbo.FileStatsHistory

INSERT INTO dbo.FileStatsHistory (FileStatsID, [DBName], [DBID], [FileID], [FileName], LogicalFileName, VLFCount, DriveLetter, FileMBSize, FileMaxSize, FileGrowth, FileMBUsed, 
	FileMBEmpty, FilePercentEmpty, LargeLDF, [FileGroup], NumberReads, KBytesRead, NumberWrites, KBytesWritten, IoStallReadMS, IoStallWriteMS, Cum_IO_GB, IO_Percent)
SELECT @FileStatsID AS FileStatsID,[DBName], [DBID], [FileID], [FileName], LogicalFileName, VLFCount, DriveLetter, FileMBSize, FileMaxSize, FileGrowth, FileMBUsed, 
	FileMBEmpty, FilePercentEmpty, LargeLDF, [FileGroup], NumberReads, KBytesRead, NumberWrites, KBytesWritten, IoStallReadMS, IoStallWriteMS, Cum_IO_GB, IO_Percent
FROM #FILESTATS

END
DROP TABLE #FILESTATS
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_CheckFiles' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_CheckFiles AS SELECT 1')
END
GO

ALTER PROC [dbo].[usp_CheckFiles]
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**  06/10/2012		Michael Rounds			1.1					Updated to use new FileStatsHistory table
**	08/31/2012		Michael Rounds			1.2					Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN

SET NOCOUNT ON

/* GET STATS */

/*Populate File Stats tables*/
EXEC [dba].dbo.usp_FileStats @InsertFlag=1

DECLARE @FileStatsID INT, @QueryValue INT, @QueryValue2 INT, @HTML NVARCHAR(MAX), @EmailList NVARCHAR(255), @CellList NVARCHAR(255), @ServerName NVARCHAR(128), @EmailSubject NVARCHAR(100)

SELECT @ServerName = CONVERT(NVARCHAR(128), SERVERPROPERTY('servername'))  

SET @FileStatsID = (SELECT MAX(FileStatsID) FROM [dba].dbo.FileStatsHistory)

/*Populate Main TEMP table*/
SELECT FileStatsHistoryID, FileStatsID, FileStatsDateStamp, [DBName], [FileName], DriveLetter, FileMBSize, FileGrowth, FileMBUsed, FileMBEmpty, FilePercentEmpty
INTO #TEMP
FROM [dba].dbo.FileStatsHistory
WHERE FileStatsID IN (@FileStatsID,(@FileStatsID -1 ))

/* LOG FILES */

/*Grab AlertSettings for LogFiles*/
SELECT @QueryValue = QueryValue,
		@QueryValue2 = QueryValue2,
		@EmailList = EmailList,
		@CellList = CellList
FROM [dba].dbo.AlertSettings WHERE Name = 'LogFiles'

CREATE TABLE #TEMP2 (
	[DBName] NVARCHAR(128),
	FileMBSize BIGINT,
	FileMBUsed BIGINT,
	FileMBEmpty BIGINT,
	FilePercentEmpty NUMERIC(12,2)
	)

INSERT INTO #TEMP2 ([DBName],FileMBSize,FileMBUsed,FileMBEmpty,FilePercentEmpty)
SELECT t2.[DBName],t2.FileMBSize,t2.FileMBUsed,t2.FileMBEmpty,CAST(t2.FilePercentEmpty AS NUMERIC(12,2))
FROM #TEMP t
JOIN #TEMP t2
	ON t.[DBName] = t2.[DBName] 
	AND t.[Filename] = t2.[FileName] 
	AND t.FileStatsID = (SELECT MIN(FileStatsID) FROM #TEMP) 
	AND t2.FileStatsID = (SELECT MAX(FileStatsID) FROM #TEMP)
WHERE CAST(t2.FilePercentEmpty AS NUMERIC(12,2)) < @QueryValue
AND t2.[Filename] like '%ldf'
AND t.FileMBSize <> t2.FileMBSize
AND t2.[DBName] NOT IN ('model','tempdb')
AND t2.[DBName] NOT IN (SELECT [DBName] FROM [dba].dbo.DatabaseSettings WHERE LogFileAlerts = 0)

/*Populate TEMPLogFiles table used for Already Grown LOG files*/

CREATE TABLE #TEMPLogFiles (
	[DBName] NVARCHAR(128),
	[Filename] NVARCHAR(255),
	PreviousFileSize BIGINT,
	PrevPercentEmpty NUMERIC(12,2),
	CurrentFileSize BIGINT,
	CurrPercentEmpty NUMERIC(12,2)	
	)

INSERT INTO #TEMPLogFiles ([DBName],[Filename],PreviousFileSize,PrevPercentEmpty,CurrentFileSize,CurrPercentEmpty)
SELECT t.[DBName],t.[Filename],t.FileMBSize AS PreviousFileSize,t.FilePercentEmpty AS PrevPercentEmpty,t2.FileMBSize AS CurrentFileSize,t2.FilePercentEmpty AS CurrPercentEmpty
FROM #TEMP t
JOIN #TEMP t2
	ON t.[DBName] = t2.[DBName] 
	AND t.[Filename] = t2.[FileName] 
	AND t.FileStatsID = (SELECT MIN(FileStatsID) FROM #TEMP) 
	AND t2.FileStatsID = (SELECT MAX(FileStatsID) FROM #TEMP)
WHERE t2.[Filename] like '%ldf'
AND t.FileMBSize < t2.FileMBSize
AND t2.[DBName] NOT IN ('model','tempdb')
AND t2.[DBName] NOT IN (SELECT [DBName] FROM [dba].dbo.DatabaseSettings WHERE LogFileAlerts = 0)

/*Start of Growing Log files*/
IF EXISTS (SELECT * FROM #TEMP2)
BEGIN
SET	@HTML =
	'<html><head><style type="text/css">
	table { border: 0px; border-spacing: 0px; border-collapse: collapse;}
	th {color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;border: 0;}
	th.header {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;}
	td {font-size:11px; font-family:arial;border-right: 0;border-bottom: 1px solid #C1DAD7;padding: 5px 5px 5px 8px;}
	</style></head><body>
	<table width="725"> <tr><th class="header" width="725">Growing Log Files</th></tr></table>
	<table width="725" >
	<tr>  
	<th width="250">Database</th>
	<th width="250">FileMBSize</th>
	<th width="250">FileMBUsed</th> 
	<th width="250">FileMBEmpty</th>
	<th width="250">FilePercentEmpty</th>
	</tr>'
SELECT @HTML =  @HTML +   
	'<tr>
	<td bgcolor="#E0E0E0" width="250">' + [DBName] +'</td>
	<td bgcolor="#F0F0F0" width="250">' + CAST(FileMBSize AS NVARCHAR) + '</td>	
	<td bgcolor="#E0E0E0" width="250">' + CAST(FileMBUsed AS NVARCHAR) + '</td>	
	<td bgcolor="#F0F0F0" width="250">' + CAST(FileMBEmpty AS NVARCHAR) + '</td>	
	<td bgcolor="#E0E0E0" width="250">' + CAST(FilePercentEmpty AS NVARCHAR) + '</td>			
	</tr>'
FROM #TEMP2

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'Log files are about to Auto-Grow on ' + @ServerName + '!'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @EmailList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

IF @CellList IS NOT NULL
BEGIN

IF @QueryValue2 IS NOT NULL
BEGIN
TRUNCATE TABLE #TEMP2
INSERT INTO #TEMP2 ([DBName],FileMBSize,FileMBUsed,FileMBEmpty,FilePercentEmpty)
SELECT t2.[DBName],t2.FileMBSize,t2.FileMBUsed,t2.FileMBEmpty,t2.FilePercentEmpty
FROM #TEMP t
JOIN #TEMP t2
	ON t.[DBName] = t2.[DBName] 
	AND t.[Filename] = t2.[FileName] 
	AND t.FileStatsID = (SELECT MIN(FileStatsID) FROM #TEMP) 
	AND t2.FileStatsID = (SELECT MAX(FileStatsID) FROM #TEMP)
WHERE t2.FilePercentEmpty < @QueryValue2
AND t2.[Filename] like '%ldf'
AND t.FileMBSize <> t2.FileMBSize
AND t2.[DBName] NOT IN ('model','tempdb')
AND t2.[DBName] NOT IN (SELECT [DBName] FROM [dba].dbo.DatabaseSettings WHERE LogFileAlerts = 0)
END

/*TEXT MESSAGE*/
IF EXISTS (SELECT * FROM #TEMP2)
BEGIN
SET	@HTML =
	'<html><head></head><body><table><tr><td>Database,</td><td>FileSize,</td><td>Percent</td></tr>'
SELECT @HTML =  @HTML +   
	'<tr><td>' + COALESCE([DBName], '') +',</td><td>' + COALESCE(CAST(FileMBSize AS NVARCHAR), '') +',</td><td>' + COALESCE(CAST(FilePercentEmpty AS NVARCHAR), '') +'</td></tr>'
FROM #TEMP2
SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'LDFGrowing-' + @ServerName

EXEC msdb.dbo.sp_send_dbmail
@recipients= @CellList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

END
END
END
/*Stop of Growing Log files*/
/*Start of Already Grown Log files*/
IF EXISTS (SELECT * FROM #TEMPLogFiles)
BEGIN
SET	@HTML =
	'<html><head><style type="text/css">
	table { border: 0px; border-spacing: 0px; border-collapse: collapse;}
	th {color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;border: 0;}
	th.header {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;}
	td {font-size:11px; font-family:arial;border-right: 0;border-bottom: 1px solid #C1DAD7;padding: 5px 5px 5px 8px;}
	</style></head><body>
	<table width="725"> <tr><th class="header" width="725">Recent Log File Auto-Growth</th></tr></table>
	<table width="725" >
	<tr>  
	<th width="250">Database</th>
	<th width="250">PreviousFileSize</th>
	<th width="250">PrevPercentEmpty</th>
	<th width="250">CurrentFileSize</th>
	<th width="250">CurrPercentEmpty</th>
	</tr>'
SELECT @HTML =  @HTML +   
	'<tr>
	<td bgcolor="#E0E0E0" width="250">' + [DBName] +'</td>
	<td bgcolor="#F0F0F0" width="250">' + CAST(PreviousFileSize AS NVARCHAR) + '</td>	
	<td bgcolor="#E0E0E0" width="250">' + CAST(PrevPercentEmpty AS NVARCHAR) + '</td>	
	<td bgcolor="#F0F0F0" width="250">' + CAST(CurrentFileSize AS NVARCHAR) + '</td>	
	<td bgcolor="#E0E0E0" width="250">' + CAST(CurrPercentEmpty AS NVARCHAR) + '</td>			
	</tr>'
FROM #TEMPLogFiles

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'Log files have Auto-Grown on ' + @ServerName + '!'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @EmailList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

IF @CellList IS NOT NULL
BEGIN
/*TEXT MESSAGE*/
SET	@HTML =
	'<html><head></head><body><table><tr><td>Database,</td><td>PrevFileSize,</td><td>CurrFileSize</td></tr>'
SELECT @HTML =  @HTML +   
	'<tr><td>' + COALESCE([DBName], '') +',</td><td>' + COALESCE(CAST(PreviousFileSize AS NVARCHAR), '') +',</td><td>' + COALESCE(CAST(CurrentFileSize AS NVARCHAR), '') +'</td></tr>'
FROM #TEMPLogFiles
SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'LDFAutoGrowth-' + @ServerName

EXEC msdb.dbo.sp_send_dbmail
@recipients= @CellList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

END
END
/*Stop of Already Grown Log files*/

/* TEMP DB */

/*Grab AlertSettings for TEMPDB*/
SELECT @QueryValue = QueryValue,
		@QueryValue2 = QueryValue2,
		@EmailList = EmailList,
		@CellList = CellList
FROM [dba].dbo.AlertSettings WHERE Name = 'TempDB'

CREATE TABLE #TEMP3 (
	[DBName] NVARCHAR(128),
	FileMBSize BIGINT,
	FileMBUsed BIGINT,
	FileMBEmpty BIGINT,
	FilePercentEmpty NUMERIC(12,2)
	)

INSERT INTO #TEMP3
SELECT t2.[DBName],t2.FileMBSize,t2.FileMBUsed,t2.FileMBEmpty,CAST(t2.FilePercentEmpty AS NUMERIC(12,2))
FROM #TEMP t
JOIN #TEMP t2
	ON t.[DBName] = t2.[DBName] 
	AND t.[Filename] = t2.[FileName] 
	AND t.FileStatsID = (SELECT MIN(FileStatsID) FROM #TEMP) 
	AND t2.FileStatsID = (SELECT MAX(FileStatsID) FROM #TEMP)
WHERE CAST(t2.FilePercentEmpty AS NUMERIC(12,2)) < @QueryValue
AND t2.[Filename] like '%mdf'
AND t.FileMBSize <> t2.FileMBSize
AND t2.[DBName] = 'tempdb'

/*Populate TEMPdb table used for Already Grown TEMPDB files*/
CREATE TABLE #TEMPdb (
	[DBName] NVARCHAR(128),
	[Filename] NVARCHAR(255),
	PreviousFileSize BIGINT,
	PrevPercentEmpty NUMERIC(12,2),
	CurrentFileSize BIGINT,
	CurrPercentEmpty NUMERIC(12,2)	
	)

INSERT INTO #TEMPdb
SELECT t2.[DBName],t2.[Filename],t.FileMBSize AS PreviousFileSize,t.FilePercentEmpty AS PrevPercentEmpty,t2.FileMBSize AS CurrentFileSize,t2.FilePercentEmpty AS CurrPercentEmpty
FROM #TEMP t
JOIN #TEMP t2
	ON t.[DBName] = t2.[DBName] 
	AND t.[Filename] = t2.[FileName] 
	AND t.FileStatsID = (SELECT MIN(FileStatsID) FROM #TEMP) 
	AND t2.FileStatsID = (SELECT MAX(FileStatsID) FROM #TEMP)
WHERE t2.[Filename] like '%mdf'
AND t.FileMBSize < t2.FileMBSize
AND t2.[DBName] = 'tempdb'

/*Start of TempDB Growing*/
IF EXISTS (SELECT * FROM #TEMP3)
BEGIN
SET	@HTML =
	'<html><head><style type="text/css">
	table { border: 0px; border-spacing: 0px; border-collapse: collapse;}
	th {color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;border: 0;}
	th.header {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;}
	td {font-size:11px; font-family:arial;border-right: 0;border-bottom: 1px solid #C1DAD7;padding: 5px 5px 5px 8px;}
	</style></head><body>
	<table width="725"> <tr><th class="header" width="725">TempDB Growth</th></tr></table>
	<table width="725" >
	<tr>  
	<th width="250">Database</th>
	<th width="250">FileMBSize</th>
	<th width="250">FileMBUsed</th> 
	<th width="250">FileMBEmpty</th>
	<th width="250">FilePercentEmpty</th>
	</tr>'
SELECT @HTML =  @HTML +   
	'<tr>
	<td bgcolor="#E0E0E0" width="250">' + [DBName] +'</td>
	<td bgcolor="#F0F0F0" width="250">' + CAST(FileMBSize AS NVARCHAR) + '</td>	
	<td bgcolor="#E0E0E0" width="250">' + CAST(FileMBUsed AS NVARCHAR) + '</td>	
	<td bgcolor="#F0F0F0" width="250">' + CAST(FileMBEmpty AS NVARCHAR) + '</td>	
	<td bgcolor="#E0E0E0" width="250">' + CAST(FilePercentEmpty AS NVARCHAR) + '</td>			
	</tr>'
FROM #TEMP3

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'TempDB is growing on ' + @ServerName + '!'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @EmailList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

IF @CellList IS NOT NULL
BEGIN

IF @QueryValue2 IS NOT NULL
BEGIN
TRUNCATE TABLE #TEMP3
INSERT INTO #TEMP3
SELECT t2.[DBName],t2.FileMBSize,t2.FileMBUsed,t2.FileMBEmpty,t2.FilePercentEmpty
FROM #TEMP t
JOIN #TEMP t2
	ON t.[DBName] = t2.[DBName] 
	AND t.[Filename] = t2.[FileName] 
	AND t.FileStatsID = (SELECT MIN(FileStatsID) FROM #TEMP) 
	AND t2.FileStatsID = (SELECT MAX(FileStatsID) FROM #TEMP)
WHERE t2.FilePercentEmpty < @QueryValue
AND t2.[Filename] like '%mdf'
AND t.FileMBSize <> t2.FileMBSize
AND t2.[DBName] = 'tempdb'
END

/*TEXT MESSAGE*/
IF EXISTS (SELECT * FROM #TEMP3)
BEGIN
SET	@HTML =
	'<html><head></head><body><table><tr><td>FileSize,</td><td>FileEmpty,</td><td>Percent</td></tr>'
SELECT @HTML =  @HTML +   
	'<tr><td>' + COALESCE(CAST(FileMBSize AS NVARCHAR), '') +',</td><td>' + COALESCE(CAST(FileMBEmpty AS NVARCHAR), '') +',</td><td>' + COALESCE(CAST(FilePercentEmpty AS NVARCHAR), '') +'</td></tr>'
FROM #TEMP3

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'TempDBGrowing-' + @ServerName

EXEC msdb.dbo.sp_send_dbmail
@recipients= @CellList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

END
END
END
/*Stop of TempDB Growing*/
/*Start of TempDB Already Grown*/

/*TempDB */
IF EXISTS (SELECT * FROM #TEMPdb)
BEGIN
SET	@HTML =
	'<html><head><style type="text/css">
	table { border: 0px; border-spacing: 0px; border-collapse: collapse;}
	th {color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;border: 0;}
	th.header {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;}
	td {font-size:11px; font-family:arial;border-right: 0;border-bottom: 1px solid #C1DAD7;padding: 5px 5px 5px 8px;}
	</style></head><body>
	<table width="725"> <tr><th class="header" width="725">Recent TempDB Auto-Growth</th></tr></table>
	<table width="725" >
	<tr>  
	<th width="250">Database</th>
	<th width="250">PreviousFileSize</th>
	<th width="250">PrevPercentEmpty</th>
	<th width="250">CurrentFileSize</th>
	<th width="250">CurrPercentEmpty</th>
	</tr>'
SELECT @HTML =  @HTML +   
	'<tr>
	<td bgcolor="#E0E0E0" width="250">' + [DBName] +'</td>
	<td bgcolor="#F0F0F0" width="250">' + CAST(PreviousFileSize AS NVARCHAR) + '</td>	
	<td bgcolor="#E0E0E0" width="250">' + CAST(PrevPercentEmpty AS NVARCHAR) + '</td>	
	<td bgcolor="#F0F0F0" width="250">' + CAST(CurrentFileSize AS NVARCHAR) + '</td>	
	<td bgcolor="#E0E0E0" width="250">' + CAST(CurrPercentEmpty AS NVARCHAR) + '</td>			
	</tr>'
FROM #TEMPdb

SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'TempDB has Auto-Grown on ' + @ServerName + '!'

EXEC msdb.dbo.sp_send_dbmail
@recipients= @EmailList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

IF @CellList IS NOT NULL
BEGIN
/*TEXT MESSAGE*/
SET	@HTML =
	'<html><head></head><body><table><tr><td>Database,</td><td>PrevFileSize,</td><td>CurrFileSize</td></tr>'
SELECT @HTML =  @HTML +   
	'<tr><td>' + COALESCE([DBName], '') +',</td><td>' + COALESCE(CAST(PreviousFileSize AS NVARCHAR), '') +',</td><td>' + COALESCE(CAST(CurrentFileSize AS NVARCHAR), '') +'</td></tr>'
FROM #TEMPdb
SELECT @HTML =  @HTML + '</table></body></html>'

SELECT @EmailSubject = 'TempDBAutoGrowth-' + @ServerName

EXEC msdb.dbo.sp_send_dbmail
@recipients= @CellList,
@subject = @EmailSubject,
@body = @HTML,
@body_format = 'HTML'

END
END
DROP TABLE #TEMPLogFiles
DROP TABLE #TEMPdb
DROP TABLE #TEMP
DROP TABLE #TEMP2
DROP TABLE #TEMP3

END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'dd_PopulateDataDictionary' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.dd_PopulateDataDictionary AS SELECT 1')
END
GO

ALTER PROC dbo.dd_PopulateDataDictionary
AS

/**************************************************************************************************************
**  Purpose: RUN THIS TO POPULATE DATA DICTIONARY PROCESS TABLES
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  11/06/2012		Michael Rounds			1.0					Comments creation
***************************************************************************************************************/

    SET NOCOUNT ON
    DECLARE @TableCount INT,
        @FieldCount INT
    INSERT  INTO dbo.DataDictionary_Tables ( SchemaName, TableName )
            SELECT  SRC.TABLE_SCHEMA,
                    TABLE_NAME
            FROM    INFORMATION_SCHEMA.TABLES AS SRC
                    LEFT JOIN dbo.DataDictionary_Tables AS DEST
                        ON SRC.table_Schema = DEST.SchemaName
                           AND SRC.table_name = DEST.TableName
            WHERE   DEST.SchemaName IS NULL
                    AND SRC.table_Type = 'BASE TABLE'
                    AND OBJECTPROPERTY(OBJECT_ID(QUOTENAME(SRC.TABLE_SCHEMA)
                                                 + '.'
                                                 + QUOTENAME(SRC.TABLE_NAME)),
                                       'IsMSShipped') = 0
    SET @TableCount = @@ROWCOUNT
    INSERT  INTO dbo.DataDictionary_Fields
            (
              SchemaName,
              TableName,
              FieldName
            )
            SELECT  C.TABLE_SCHEMA,
                    C.TABLE_NAME,
                    C.COLUMN_NAME
            FROM    INFORMATION_SCHEMA.COLUMNS AS C
                    INNER JOIN dbo.DataDictionary_Tables AS T
                        ON C.TABLE_SCHEMA = T.SchemaName
                           AND C.TABLE_NAME = T.TableName
                    LEFT JOIN dbo.DataDictionary_Fields AS F
                        ON C.TABLE_SCHEMA = F.SchemaName
                           AND C.TABLE_NAME = F.TableName
                           AND C.COLUMN_NAME = F.FieldName
            WHERE   F.SchemaName IS NULL
                    AND OBJECTPROPERTY(OBJECT_ID(QUOTENAME(C.TABLE_SCHEMA)
                                                 + '.'
                                                 + QUOTENAME(C.TABLE_NAME)),
                                       'IsMSShipped') = 0
    SET @FieldCount = @@ROWCOUNT
    RAISERROR ( 'DATA DICTIONARY: %i tables & %i fields added', 10, 1,
        @TableCount, @FieldCount ) WITH NOWAIT
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'dd_UpdateDataDictionaryTable' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.dd_UpdateDataDictionaryTable AS SELECT 1') 
END
GO

ALTER PROC dbo.dd_UpdateDataDictionaryTable
    @SchemaName sysname = N'dbo',
    @TableName sysname, 
    @TableDescription VARCHAR(7000) = '' 
AS

/**************************************************************************************************************
**  Purpose: USE THIS TO MANUALLY UPDATE AN INDIVIDUAL TABLE/FIELD, THEN RUN POPULATE SCRIPT AGAIN
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  11/06/2012		Michael Rounds			1.0					Comments creation
***************************************************************************************************************/

    SET NOCOUNT ON
    UPDATE  dbo.DataDictionary_Tables
    SET     TableDescription = ISNULL(@TableDescription, '')
    WHERE   SchemaName = @SchemaName
            AND TableName = @TableName
    RETURN @@ROWCOUNT
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'dd_UpdateDataDictionaryField' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.dd_UpdateDataDictionaryField AS SELECT 1')
END
GO

ALTER PROC dbo.dd_UpdateDataDictionaryField
    @SchemaName sysname = N'dbo',
    @TableName sysname, 
    @FieldName sysname, 
    @FieldDescription VARCHAR(7000) = '' 
AS

/**************************************************************************************************************
**  Purpose: USE THIS TO MANUALLY UPDATE AN INDIVIDUAL TABLE/FIELD, THEN RUN POPULATE SCRIPT AGAIN
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  11/06/2012		Michael Rounds			1.0					Comments creation
***************************************************************************************************************/

    SET NOCOUNT ON
    UPDATE  dbo.DataDictionary_Fields
    SET     FieldDescription = ISNULL(@FieldDescription, '')
    WHERE   SchemaName = @SchemaName
            AND TableName = @TableName
            AND FieldName = @FieldName
    RETURN @@ROWCOUNT
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'dd_TestDataDictionaryTables' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.dd_TestDataDictionaryTables AS SELECT 1')
END
GO

ALTER PROC dbo.dd_TestDataDictionaryTables
AS

/**************************************************************************************************************
**  Purpose: RUN THIS TO FIND TABLES AND/OR FIELDS THAT ARE MISSING DATA
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  11/06/2012		Michael Rounds			1.0					Comments creation
***************************************************************************************************************/

    SET NOCOUNT ON
    DECLARE @TableList TABLE
        (
          SchemaName sysname NOT NULL,
          TableName SYSNAME NOT NULL,
          PRIMARY KEY CLUSTERED ( SchemaName, TableName )
        )
    DECLARE @RecordCount INT
    EXEC dbo.dd_PopulateDataDictionary -- Ensure the dbo.DataDictionary tables are up-to-date.
    INSERT  INTO @TableList ( SchemaName, TableName )
            SELECT  SchemaName,
                    TableName
            FROM    dbo.DataDictionary_Tables
            WHERE   TableName NOT LIKE 'MSp%' -- ???
                    AND TableName NOT LIKE 'sys%' -- Exclude standard system tables.
                    AND TableDescription = ''
    SET @RecordCount = @@ROWCOUNT
    IF @RecordCount > 0 
        BEGIN
            PRINT ''
            PRINT 'The following recordset shows the tables for which data dictionary descriptions are missing'
            PRINT ''
            SELECT  LEFT(SchemaName, 15) AS SchemaName,
                    LEFT(TableName, 30) AS TableName
            FROM    @TableList
            UNION ALL
            SELECT  '',
                    '' -- Used to force a blank line
            RAISERROR ( '%i table(s) lack descriptions', 16, 1, @RecordCount )
                WITH NOWAIT
        END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'dd_TestDataDictionaryFields' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.dd_TestDataDictionaryFields AS SELECT 1')
END
GO

ALTER PROC dbo.dd_TestDataDictionaryFields
AS

/**************************************************************************************************************
**  Purpose: RUN THIS TO FIND TABLES AND/OR FIELDS THAT ARE MISSING DATA
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  11/06/2012		Michael Rounds			1.0					Comments creation
***************************************************************************************************************/

    SET NOCOUNT ON
    DECLARE @RecordCount INT
    DECLARE @FieldList TABLE
        (
          SchemaName sysname NOT NULL,
          TableName SYSNAME NOT NULL,
          FieldName sysname NOT NULL,
          PRIMARY KEY CLUSTERED ( SchemaName, TableName, FieldName )
        )
    EXEC dbo.dd_PopulateDataDictionary -- Ensure the dbo.DataDictionary tables are up-to-date.
    INSERT  INTO @FieldList
            (
              SchemaName,
              TableName,
              FieldName
            )
            SELECT  SchemaName,
                    TableName,
                    FieldName
            FROM    dbo.DataDictionary_Fields
            WHERE   TableName NOT LIKE 'MSp%' -- ???
                    AND TableName NOT LIKE 'sys%' -- Exclude standard system tables.
                    AND FieldDescription = ''
    SET @RecordCount = @@ROWCOUNT
    IF @RecordCount > 0 
        BEGIN
            PRINT ''
            PRINT 'The following recordset shows the tables/fields for which data dictionary descriptions are missing'
            PRINT ''
            SELECT  LEFT(SchemaName, 15) AS SchemaName,
                    LEFT(TableName, 30) AS TableName,
                    LEFT(FieldName, 30) AS FieldName
            FROM    @FieldList
            UNION ALL
            SELECT  '',
                    '',
                    '' -- Used to force a blank line
            RAISERROR ( '%i field(s) lack descriptions', 16, 1, @RecordCount )
                WITH NOWAIT
        END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'dd_ApplyDataDictionary' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.dd_ApplyDataDictionary AS SELECT 1') 
END
GO

ALTER PROC dbo.dd_ApplyDataDictionary
AS

/**************************************************************************************************************
**  Purpose: RUN THIS WHEN YOU ARE READY TO APPLY DATA DICTIONARY TO THE EXTENDED PROPERTIES TABLES
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  11/06/2012		Michael Rounds			1.0					Comments creation
***************************************************************************************************************/

    SET NOCOUNT ON
    DECLARE @SQLVersion VARCHAR(30),
        @SchemaOrUser sysname

    SET @SQLVersion = CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion'))
    IF CAST(LEFT(@SQLVersion, CHARINDEX('.', @SQLVersion) - 1) AS TINYINT) < 9 
        SET @SchemaOrUser = 'User'
    ELSE 
        SET @SchemaOrUser = 'Schema'

    DECLARE @SchemaName sysname,
        @TableName sysname,
        @FieldName sysname,
        @ObjectDescription VARCHAR(7000)
	
    DECLARE csr_dd CURSOR FAST_FORWARD
        FOR SELECT  DT.SchemaName,
                    DT.TableName,
                    DT.TableDescription
            FROM    dbo.DataDictionary_Tables AS DT
                    INNER JOIN INFORMATION_SCHEMA.TABLES AS T
                        ON DT.SchemaName COLLATE Latin1_General_CI_AS = T.TABLE_SCHEMA COLLATE Latin1_General_CI_AS
                           AND DT.TableName COLLATE Latin1_General_CI_AS = T.TABLE_NAME COLLATE Latin1_General_CI_AS
            WHERE   DT.TableDescription <> ''
	
    OPEN csr_dd
    FETCH NEXT FROM csr_dd INTO @SchemaName, @TableName, @ObjectDescription
    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF EXISTS ( SELECT  1
                        FROM    ::fn_listextendedproperty(NULL, @SchemaOrUser,
                                                        @SchemaName, 'table',
                                                        @TableName, default,
                                                        default) ) 
                EXECUTE sp_updateextendedproperty N'MS_Description',
                    @ObjectDescription, @SchemaOrUser, @SchemaName, N'table',
                    @TableName, NULL, NULL
            ELSE 
                EXECUTE sp_addextendedproperty N'MS_Description',
                    @ObjectDescription, @SchemaOrUser, @SchemaName, N'table',
                    @TableName, NULL, NULL
	
            RAISERROR ( 'DOCUMENTED TABLE: %s', 10, 1, @TableName ) WITH NOWAIT
            FETCH NEXT FROM csr_dd INTO @SchemaName, @TableName,
                @ObjectDescription
        END
    CLOSE csr_dd
    DEALLOCATE csr_dd
    DECLARE csr_ddf CURSOR FAST_FORWARD
        FOR SELECT  DT.SchemaName,
                    DT.TableName,
                    DT.FieldName,
                    DT.FieldDescription
            FROM    dbo.DataDictionary_Fields AS DT
                    INNER JOIN INFORMATION_SCHEMA.COLUMNS AS T
                        ON DT.SchemaName COLLATE Latin1_General_CI_AS = T.TABLE_SCHEMA COLLATE Latin1_General_CI_AS
                           AND DT.TableName COLLATE Latin1_General_CI_AS = T.TABLE_NAME COLLATE Latin1_General_CI_AS
                           AND DT.FieldName COLLATE Latin1_General_CI_AS = T.COLUMN_NAME COLLATE Latin1_General_CI_AS
            WHERE   DT.FieldDescription <> ''
    OPEN csr_ddf
    FETCH NEXT FROM csr_ddf INTO @SchemaName, @TableName, @FieldName,
        @ObjectDescription
    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF EXISTS ( SELECT  *
                        FROM    ::fn_listextendedproperty(NULL, @SchemaOrUser,
                                                        @SchemaName, 'table',
                                                        @TableName, 'column',
                                                        @FieldName) ) 
                EXECUTE sp_updateextendedproperty N'MS_Description',
                    @ObjectDescription, @SchemaOrUser, @SchemaName, N'table',
                    @TableName, N'column', @FieldName
            ELSE 
                EXECUTE sp_addextendedproperty N'MS_Description',
                    @ObjectDescription, @SchemaOrUser, @SchemaName, N'table',
                    @TableName, N'column', @FieldName
            RAISERROR ( 'DOCUMENTED FIELD: %s.%s', 10, 1, @TableName,
                @FieldName ) WITH NOWAIT
            FETCH NEXT FROM csr_ddf INTO @SchemaName, @TableName, @FieldName,
                @ObjectDescription
        END
    CLOSE csr_ddf
    DEALLOCATE csr_ddf
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'dd_ScavengeDataDictionaryTables' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.dd_ScavengeDataDictionaryTables AS SELECT 1')
END
GO

ALTER PROC dbo.dd_ScavengeDataDictionaryTables
AS

/**************************************************************************************************************
**  Purpose:
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  11/06/2012		Michael Rounds			1.0					Comments creation
***************************************************************************************************************/

    SET NOCOUNT ON
    IF OBJECT_ID('tempdb..#DataDictionaryTables') IS NOT NULL 
        DROP TABLE #DataDictionaryTables
    DECLARE @SchemaOrUser sysname,
        @SQLVersion VARCHAR(30),
        @SchemaName sysname 
    SET @SQLVersion = CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion'))
    SET @SchemaName = ''
    DECLARE @SchemaList TABLE
        (
          SchemaName sysname NOT NULL
                             PRIMARY KEY CLUSTERED
        )
    INSERT  INTO @SchemaList ( SchemaName )
            SELECT DISTINCT
                    TABLE_SCHEMA
            FROM    INFORMATION_SCHEMA.TABLES
            WHERE   TABLE_TYPE = 'BASE TABLE'
    IF CAST(LEFT(@SQLVersion, CHARINDEX('.', @SQLVersion) - 1) AS TINYINT) < 9 
        SET @SchemaOrUser = 'User'
    ELSE 
        SET @SchemaOrUser = 'Schema'
	
    CREATE TABLE #DataDictionaryTables
        (
          objtype sysname NOT NULL,
          TableName sysname NOT NULL,
          PropertyName sysname NOT NULL,
          TableDescription VARCHAR(7000) NULL
        )
    WHILE @SchemaName IS NOT NULL
        BEGIN
            TRUNCATE TABLE #DataDictionaryTables
		
            SELECT  @SchemaName = MIN(SchemaName)
            FROM    @SchemaList
            WHERE   SchemaName > @SchemaName
		
            IF @SchemaName IS NOT NULL 
                BEGIN
                    RAISERROR ( 'Scavenging schema %s', 10, 1, @SchemaName )
                        WITH NOWAIT
                    INSERT  INTO #DataDictionaryTables
                            (
                              objtype,
                              TableName,
                              PropertyName,
                              TableDescription
						
                            )
                            SELECT  objtype,
                                    objname,
                                    name,
                                    CONVERT(VARCHAR(7000), value)
                            FROM    ::fn_listextendedproperty(NULL,
                                                            @SchemaOrUser,
                                                            @SchemaName,
                                                            'table', default,
                                                            default, default)
                            WHERE   name = 'MS_DESCRIPTION'
                    UPDATE  DT_DEST
                    SET     DT_DEST.TableDescription = DT_SRC.TableDescription
                    FROM    #DataDictionaryTables AS DT_SRC
                            INNER JOIN dbo.DataDictionary_Tables AS DT_DEST
                                ON DT_SRC.TableName COLLATE Latin1_General_CI_AS = DT_DEST.TableName COLLATE Latin1_General_CI_AS
                    WHERE   DT_DEST.SchemaName COLLATE Latin1_General_CI_AS = @SchemaName COLLATE Latin1_General_CI_AS
                            AND DT_SRC.TableDescription IS NOT NULL
                            AND DT_SRC.TableDescription <> ''
                END
        END
    IF OBJECT_ID('tempdb..#DataDictionaryTables') IS NOT NULL 
        DROP TABLE #DataDictionaryTables
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'dd_ScavengeDataDictionaryFields' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.dd_ScavengeDataDictionaryFields AS SELECT 1')
END
GO

ALTER PROC dbo.dd_ScavengeDataDictionaryFields
AS

/**************************************************************************************************************
**  Purpose:
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  11/06/2012		Michael Rounds			1.0					Comments creation
***************************************************************************************************************/

SET NOCOUNT ON
IF OBJECT_ID('tempdb..#DataDictionaryFields') IS NOT NULL
     DROP TABLE #DataDictionaryFields
IF OBJECT_ID('tempdb..#TableList') IS NOT NULL
     DROP TABLE #TableList
DECLARE 
    @SchemaOrUser sysname,
    @SQLVersion VARCHAR(30),
    @SchemaName sysname ,
    @TableName sysname
SET @SQLVersion = CONVERT(VARCHAR,SERVERPROPERTY('ProductVersion'))

CREATE TABLE #TableList(SchemaName sysname NOT null,TableName sysname NOT NULL)
INSERT INTO #TableList(SchemaName,TableName)
SELECT TABLE_SCHEMA,TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE='BASE TABLE'

IF CAST(LEFT(@SQLVersion,CHARINDEX('.',@SQLVersion)-1) AS TINYINT) <9
    SET @SchemaOrUser = 'User'
ELSE
    SET @SchemaOrUser='Schema'

CREATE TABLE #DataDictionaryFields (
    objtype sysname  NOT NULL,
    FieldName sysname NOT NULL,
    PropertyName sysname NOT NULL,
    FieldDescription VARCHAR(7000) NULL
)
DECLARE csr_dd CURSOR FAST_FORWARD FOR
    SELECT SchemaName,TableName
    FROM #TableList
OPEN csr_dd

FETCH NEXT FROM csr_dd INTO @SchemaName, @TableName
WHILE @@FETCH_STATUS = 0
    BEGIN
        TRUNCATE TABLE #DataDictionaryFields

        RAISERROR('Scavenging schema.table %s.%s',10,1,@SchemaName,@TableName) WITH NOWAIT
    INSERT INTO #DataDictionaryFields
                ( objtype ,
                  FieldName ,
                  PropertyName ,
                  FieldDescription
                )
        SELECT objtype ,
                objname ,
                   name ,
                   CONVERT(VARCHAR(7000),value )
        FROM   ::fn_listextendedproperty(NULL, @SchemaOrUser, @SchemaName, 'table', @TableName, 'column', default)
        WHERE name='MS_DESCRIPTION'

        UPDATE DT_DEST
        SET DT_DEST.FieldDescription = DT_SRC.FieldDescription
        FROM #DataDictionaryFields AS DT_SRC
            INNER JOIN dbo.DataDictionary_Fields AS DT_DEST
            ON DT_SRC.FieldName COLLATE Latin1_General_CI_AS = DT_DEST.FieldName COLLATE Latin1_General_CI_AS
        WHERE DT_DEST.SchemaName COLLATE Latin1_General_CI_AS = @SchemaName	COLLATE Latin1_General_CI_AS
        AND DT_DEST.TableName COLLATE Latin1_General_CI_AS = @TableName	COLLATE Latin1_General_CI_AS
        AND DT_SRC.FieldDescription IS NOT NULL AND DT_SRC.FieldDescription<>''
        FETCH NEXT FROM csr_dd INTO @SchemaName, @TableName
    END
CLOSE csr_dd
DEALLOCATE csr_dd
IF OBJECT_ID('tempdb..#DataDictionaryFields') IS NOT NULL
     DROP TABLE #DataDictionaryFields
IF OBJECT_ID('tempdb..#TableList') IS NOT NULL
     DROP TABLE #TableList
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'sp_ViewTableExtendedProperties' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.sp_ViewTableExtendedProperties AS SELECT 1')
END
GO

ALTER PROCEDURE dbo.sp_ViewTableExtendedProperties (@tablename nvarchar(255))
AS

/**************************************************************************************************************
**  Purpose:
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  11/06/2012		Michael Rounds			1.0					Comments creation
***************************************************************************************************************/

DECLARE @cmd NVARCHAR (255)

SET @cmd = 'SELECT objtype, objname, name, value FROM fn_listextendedproperty (NULL, ''schema'', ''dbo'', ''table'', ''' + @TABLENAME + ''', ''column'', default);'

EXEC sp_executesql @cmd

GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'usp_TodaysDeadlocks' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.usp_TodaysDeadlocks AS SELECT 1')
END
GO

ALTER PROC [dbo].[usp_TodaysDeadlocks]
AS
BEGIN
SET NOCOUNT ON

CREATE TABLE #DEADLOCKINFO (
	DeadlockDate DATETIME,
	DBName NVARCHAR(128),	
	ProcessInfo NVARCHAR(50),
	VictimHostname NVARCHAR(128),
	VictimLogin NVARCHAR(128),	
	VictimSPID NVARCHAR(5),
	VictimSQL NVARCHAR(MAX),
	LockingHostname NVARCHAR(128),
	LockingLogin NVARCHAR(128),
	LockingSPID NVARCHAR(5),
	LockingSQL NVARCHAR(MAX)
	)

CREATE TABLE #ERRORLOG (
	ID INT IDENTITY(1,1) NOT NULL,
	LogDate DATETIME, 
	ProcessInfo NVARCHAR(100), 
	[Text] NVARCHAR(4000),
	PRIMARY KEY (ID)
	)

INSERT INTO #ERRORLOG
EXEC sp_readerrorlog 0, 1

CREATE TABLE #TEMPDATES (LogDate DATETIME)

INSERT INTO #TEMPDATES (LogDate)
SELECT DISTINCT CONVERT(VARCHAR(30),LogDate,120) as LogDate
FROM #ERRORLOG
WHERE ProcessInfo LIKE 'spid%'
and [text] LIKE '   process id=%'

INSERT INTO #DEADLOCKINFO (DeadLockDate, DBName, ProcessInfo, VictimHostname, VictimLogin, VictimSPID, LockingHostname, LockingLogin, LockingSPID)
SELECT 
DISTINCT CONVERT(VARCHAR(30),b.LogDate,120) AS DeadlockDate,
DB_NAME(SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%currentdb=%',b.[text]),SUM((PATINDEX('%lockTimeout%',b.[text])) - (PATINDEX('%currentdb=%',b.[text])) ) )),11,50)) as DBName,
b.processinfo,
SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%hostname=%',a.[text]),SUM((PATINDEX('%hostpid%',a.[text])) - (PATINDEX('%hostname=%',a.[text])) ) )),10,50)
	AS VictimHostname,
CASE WHEN SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%loginname=%',a.[text]),SUM((PATINDEX('%isolationlevel%',a.[text])) - (PATINDEX('%loginname=%',a.[text])) ) )),11,50) NOT LIKE '%id%'
	THEN SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%loginname=%',a.[text]),SUM((PATINDEX('%isolationlevel%',a.[text])) - (PATINDEX('%loginname=%',a.[text])) ) )),11,50)
	ELSE NULL END AS VictimLogin,
CASE WHEN SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%spid=%',a.[text]),SUM((PATINDEX('%sbid%',a.[text])) - (PATINDEX('%spid=%',a.[text])) ) )),6,10) NOT LIKE '%id%'
	THEN SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%spid=%',a.[text]),SUM((PATINDEX('%sbid%',a.[text])) - (PATINDEX('%spid=%',a.[text])) ) )),6,10)
	ELSE NULL END AS VictimSPID,
SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%hostname=%',b.[text]),SUM((PATINDEX('%hostpid%',b.[text])) - (PATINDEX('%hostname=%',b.[text])) ) )),10,50)
	AS LockingHostname,
CASE WHEN SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%loginname=%',b.[text]),SUM((PATINDEX('%isolationlevel%',b.[text])) - (PATINDEX('%loginname=%',b.[text])) ) )),11,50) NOT LIKE '%id%'
	THEN SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%loginname=%',b.[text]),SUM((PATINDEX('%isolationlevel%',b.[text])) - (PATINDEX('%loginname=%',b.[text])) ) )),11,50)
	ELSE NULL END AS LockingLogin,
CASE WHEN SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%spid=%',b.[text]),SUM((PATINDEX('%sbid=%',b.[text])) - (PATINDEX('%spid=%',b.[text])) ) )),6,10) NOT LIKE '%id%'
	THEN SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%spid=%',b.[text]),SUM((PATINDEX('%sbid=%',b.[text])) - (PATINDEX('%spid=%',b.[text])) ) )),6,10)
	ELSE NULL END AS LockingSPID
FROM #TEMPDATES t
JOIN #ERRORLOG a
	ON CONVERT(VARCHAR(30),t.LogDate,120) = CONVERT(VARCHAR(30),a.LogDate,120)
JOIN #ERRORLOG b
	ON CONVERT(VARCHAR(30),t.LogDate,120) = CONVERT(VARCHAR(30),b.LogDate,120) AND a.[text] LIKE '   process id=%' AND b.[text] LIKE '   process id=%' AND a.ID < b.ID 
GROUP BY b.LogDate,b.processinfo, a.[Text], b.[Text]

SELECT 
DeadlockDate, 
DBName, 
CASE WHEN VictimLogin IS NOT NULL THEN VictimHostname ELSE NULL END AS VictimHostname, 
VictimLogin, 
CASE WHEN VictimLogin IS NOT NULL THEN VictimSPID ELSE NULL END AS VictimSPID, 
LockingHostname, 
LockingLogin,
LockingSPID
FROM #DEADLOCKINFO 
WHERE DeadlockDate >=  CONVERT(DATETIME, CONVERT (VARCHAR(10), GETDATE(), 101)) AND
(VictimLogin IS NOT NULL OR LockingLogin IS NOT NULL)
ORDER BY DeadlockDate ASC

DROP TABLE #ERRORLOG
DROP TABLE #DEADLOCKINFO
DROP TABLE #TEMPDATES

END


GO
/*========================================================================================================================
=================================================REPORT PROCS=============================================================
========================================================================================================================*/
USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'rpt_Queries' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.rpt_Queries AS SELECT 1')
END
GO

ALTER PROC dbo.rpt_Queries (@DateRangeInDays INT)
AS

BEGIN

DECLARE @QueryValue INT

SET @QueryValue = (SELECT QueryValue FROM [dba].dbo.AlertSettings (nolock) WHERE Name = 'LongRunningQueries')

SELECT
collection_time AS DateStamp,
CAST(DATEDIFF(ss,start_time,collection_time) AS INT) AS [ElapsedTime(ss)],
Session_ID AS Session_ID,
[Database_Name] AS [DBName],	
Login_Name AS Login_Name,
SQL_Text AS SQL_Text
FROM [dba].dbo.QueryHistory (nolock) 
WHERE (DATEDIFF(ss,start_time,collection_time)) >= @QueryValue 
AND (DATEDIFF(dd,collection_time,GETDATE())) <= @DateRangeInDays
AND [Database_Name] NOT IN (SELECT [DBName] FROM [dba].dbo.DatabaseSettings WHERE LongQueryAlerts = 0)
AND sql_text NOT LIKE 'BACKUP DATABASE%'
AND sql_text NOT LIKE 'RESTORE VERIFYONLY%'
AND sql_text NOT LIKE 'ALTER INDEX%'
AND sql_text NOT LIKE 'DECLARE @BlobEater%'
AND sql_text NOT LIKE 'DBCC%'
AND sql_text NOT LIKE 'WAITFOR(RECEIVE%'
ORDER BY collection_time DESC

END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'rpt_Blocking' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.rpt_Blocking AS SELECT 1')
END
GO

ALTER PROC dbo.rpt_Blocking (@DateRangeInDays INT)
AS

BEGIN

SELECT 
DateStamp,
[DBName],
Blocked_Waittime_Seconds AS [ElapsedTime(ss)],
Blocked_Spid AS VictimSPID,
Blocked_Login AS VictimLogin,
Blocked_SQL_Text AS Victim_SQL,
Blocking_Spid AS BlockerSPID,
Offending_Login AS BlockerLogin,
Offending_SQL_Text AS Blocker_SQL
FROM [dba].dbo.BlockingHistory (nolock)
WHERE (DATEDIFF(dd,DateStamp,GETDATE())) <= @DateRangeInDays
ORDER BY DateStamp DESC

END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'rpt_JobHistory' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.rpt_JobHistory AS SELECT 1')
END
GO

ALTER PROC dbo.rpt_JobHistory (@JobName NVARCHAR(50), @DateRangeInDays INT)
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.2					Comments creation
***************************************************************************************************************/

BEGIN

SELECT Job_Name AS [JobName], Run_datetime AS [RunDate], run_duration AS [RunTime], CASE WHEN run_status = 1 THEN 'Sucess' WHEN run_status = 3 THEN 'Cancelled' WHEN run_status = 0 THEN 'Error' ELSE 'N/A' END AS [RunOutcome]
FROM
(SELECT job_name, run_datetime,
        SUBSTRING(run_duration, 1, 2) + ':' + SUBSTRING(run_duration, 3, 2) + ':' +
        SUBSTRING(run_duration, 5, 2) AS run_duration, run_status
    FROM
    (SELECT j.name AS job_name,
            run_datetime = CONVERT(DATETIME, RTRIM(run_date)) +  
                (run_time * 9 + run_time % 10000 * 6 + run_time % 100 * 10) / 216e4,
            run_duration = RIGHT('000000' + CONVERT(NVARCHAR(6), run_duration), 6),
            run_status
        FROM msdb..sysjobhistory h
        JOIN msdb..sysjobs j
        ON h.job_id = j.job_id AND h.step_id = 0) t
) t
WHERE (DATEDIFF(dd,run_datetime,GETDATE())) <= @DateRangeInDays
AND job_name = @JobName
ORDER BY run_datetime DESC

END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'rpt_HealthReport'
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.rpt_HealthReport AS SELECT 1')
END
GO

ALTER PROCEDURE [dbo].[rpt_HealthReport] (@Recepients NVARCHAR(200) = NULL, @CC NVARCHAR(200) = NULL, @InsertFlag BIT = 0, @IncludePerfStats BIT = 0, @EmailFlag BIT = 1)
AS

/**************************************************************************************************************
**  Purpose: This procedure generates and emails (using DBMail) an HMTL formatted health report of the server
**
**	EXAMPLE USAGE:
**
**	SEND EMAIL WITHOUT RETAINING DATA
**		EXEC dbo.rpt_HealthReport @Recepients = 'mrounds@quiktrak.com', @CC ='mrounds@quiktrak.com', @InsertFlag = 0, @IncludePerfStats = 1
**	
**	TO POPULATE THE TABLES
**		EXEC dbo.rpt_HealthReport @Recepients = 'mrounds@quiktrak.com', @CC ='mrounds@quiktrak.com', @InsertFlag = 1, @IncludePerfStats = 1
**
**	PULL EMAIL ADDRESSES FROM ALERTSETTINGS TABLE:
**		EXEC dbo.rpt_HealthReport @Recepients = NULL, @CC = NULL, @InsertFlag = 1, @IncludePerfStats = 1
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.2					Comments creation
**	02/29/2012		Michael Rounds			1.3					Added CPU usage to PerfStats section
**  03/13/2012		Michael Rounds			1.3.1				Added Category to Job Stats section
**	03/20/2012		Michael Rounds			1.3.2				Bug fixes, optimizations
**  06/10/2012		Michael Rounds			1.3					Updated to use new FileStatsHistory table, optimized use of #JOBSTATUS
**  08/31/2012		Michael Rounds			1.4					NVARCHAR now used everywhere. Now a stand-alone proc (doesn't need DBA database or objects to run)
**	09/11/2012		Michael Rounds			1.4.1				Combined Long Running Jobs section into Jobs section
**	11/05/2012		Michael Rounds			2.0					Split out System and Server Info, Added VLF info, Added Trace Flag reporting, many bug fixes
**																	Added more File information (split out into File Info and File Stats), cleaned up error log gathering
**	11/27/2012		Michael Rounds			2.1					Tweaked Health Report to show certain elements even if there is no data (eg Trace flags)
**	12/17/2012		Michael Rounds			2.1.1				Changed Health Report to use new logic to gather file stats
**	12/27/2012		Michael Rounds			2.1.2				Fixed a bug in gathering data on db's with different coallation
**	12/31/2012		Michael Rounds			2.2					Added Deadlock section when trace flag 1222 is On.
**	01/07/2013		Michael Rounds			2.2.1				Fixed Divide by zero bug in file stats section
**	02/20/2013		Michael Rounds			2.2.3				Fixed a bug in the Deadlock section where some deadlocks weren't be included in the report
**	04/07/2013		Michael Rounds			2.2.4				Extended the lengths of KBytesRead and KBytesWritte in temp table FILESTATS - NUMERIC(12,2) to (20,2)
**	04/11/2013		Michael Rounds			2.3					Changed the File Stats section to only display last 24 hours of data instead of since last restart
**	04/12/2013		Michael Rounds			2.3.1				Added SQL Server 2012 Compatibility, Changed #TEMPDATES from SELECT INTO - > CREATE, INSERT INTO
***************************************************************************************************************/
    
BEGIN

SET NOCOUNT ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @HTML NVARCHAR(MAX),    
		@ReportTitle NVARCHAR(255),  
		@ServerName NVARCHAR(128),
		@Processor NVARCHAR(255),
		@ServerOS NVARCHAR(100),
		@SystemMemory NVARCHAR(20),
		@Days NVARCHAR(5),
		@Hours NVARCHAR(5),
		@Minutes NVARCHAR(5),
		@ISClustered NVARCHAR(10),		
		@SQLVersion NVARCHAR(500),
		@ServerStartDate DATETIME,
		@ServerMemory NVARCHAR(20),
		@ServerCollation NVARCHAR(128),
		@SingleUser NVARCHAR(5),
		@SQLAgent NVARCHAR(10),
		@StartDate DATETIME,
		@EndDate DATETIME,
		@LongQueriesQueryValue INT,
		@BlockingQueryValue INT,
		@DBName NVARCHAR(128),
		@SQL NVARCHAR(MAX),
		@Distributor NVARCHAR(128),
		@DistributionDB NVARCHAR(128),
		@DistSQL NVARCHAR(MAX),
		@MinFileStatsDateStamp DATETIME,
		@SQLVer NVARCHAR(20)

/* STEP 1: GATHER DATA */
IF @@Language <> 'us_english'
BEGIN
SET LANGUAGE us_english
END

SELECT @ReportTitle = 'Database Health Report ('+ CONVERT(NVARCHAR(128), SERVERPROPERTY('ServerName')) + ')'
SELECT @ServerName = CONVERT(NVARCHAR(128), SERVERPROPERTY('ServerName'))

CREATE TABLE #SYSTEMMEMORY (SystemMemory NUMERIC(12,2))

SELECT @SQLVer = LEFT(CONVERT(NVARCHAR(20),SERVERPROPERTY('productversion')),4)

IF CAST(@SQLVer AS NUMERIC(4,2)) < 11
BEGIN
-- (SQL 2008R2 And Below)
EXEC sp_executesql
	N'INSERT INTO #SYSTEMMEMORY (SystemMemory)
	SELECT CAST((physical_memory_in_bytes/1048576.0) / 1024 AS NUMERIC(12,2)) AS SystemMemory FROM sys.dm_os_sys_info'	
END
ELSE BEGIN
-- (SQL 2012 And Above)
EXEC sp_executesql
	N'INSERT INTO #SYSTEMMEMORY (SystemMemory)
	SELECT CAST((physical_memory_kb/1024.0) / 1024 AS NUMERIC(12,2)) AS SystemMemory FROM sys.dm_os_sys_info'
END

SELECT @SystemMemory = SystemMemory FROM #SYSTEMMEMORY

DROP TABLE #SYSTEMMEMORY

CREATE TABLE #SYSINFO (
	[Index] INT,
	Name NVARCHAR(100),
	Internal_Value BIGINT,
	Character_Value NVARCHAR(1000)
	)

INSERT INTO #SYSINFO
EXEC master.dbo.xp_msver

SELECT @ServerOS = 'Windows ' + a.[Character_Value] + ' Version ' + b.[Character_Value] 
FROM #SYSINFO a
CROSS APPLY #SYSINFO b
WHERE a.Name = 'Platform'
AND b.Name = 'WindowsVersion'

CREATE TABLE #PROCESSOR (Value NVARCHAR(128), DATA NVARCHAR(255))

INSERT INTO #PROCESSOR
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE',
            N'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
            N'ProcessorNameString';
            
SELECT @Processor = Data FROM #Processor

SELECT @ISClustered = CASE SERVERPROPERTY('IsClustered')
						WHEN 0 THEN 'No'
						WHEN 1 THEN 'Yes'
						ELSE 
						'NA' END

SELECT @ServerStartDate = crdate FROM master..sysdatabases WHERE NAME='tempdb'
SELECT @EndDate = GETDATE()
SELECT @Days = DATEDIFF(hh, @ServerStartDate, @EndDate) / 24
SELECT @Hours = DATEDIFF(hh, @ServerStartDate, @EndDate) % 24
SELECT @Minutes = DATEDIFF(mi, @ServerStartDate, @EndDate) % 60

SELECT @SQLVersion = 'Microsoft SQL Server ' + CONVERT(NVARCHAR(128), SERVERPROPERTY('productversion')) + ' ' + 
	CONVERT(NVARCHAR(128), SERVERPROPERTY('productlevel')) + ' ' + CONVERT(NVARCHAR(128), SERVERPROPERTY('edition'))

SELECT @ServerMemory = cntr_value/1024.0 FROM sys.dm_os_performance_counters WHERE counter_name = 'Total Server Memory (KB)'
SELECT @ServerCollation = CONVERT(NVARCHAR(128), SERVERPROPERTY('Collation')) 

SELECT @SingleUser = CASE SERVERPROPERTY ('IsSingleUser')
						WHEN 1 THEN 'Single'
						WHEN 0 THEN 'Multi'
						ELSE
						'NA' END

IF EXISTS (SELECT 1 FROM master..sysprocesses WHERE program_name LIKE N'SQLAgent%')
BEGIN
SET @SQLAgent = 'Up'
END ELSE
BEGIN
SET @SQLAgent = 'Down'
END

/* Cluster Info */
CREATE TABLE #CLUSTER (
	NodeName NVARCHAR(50), 
	Active BIT
	)

IF @ISClustered = 'Yes'
BEGIN

INSERT INTO #CLUSTER (NodeName)
SELECT NodeName FROM sys.dm_os_cluster_nodes 

UPDATE #CLUSTER
SET Active = 1
WHERE NodeName = (SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS'))
END

/* Trace Flag Status */
CREATE TABLE #TRACESTATUS (TraceFlag INT,[Status] BIT,[Global] BIT,[Session] BIT)

INSERT INTO #TRACESTATUS (TraceFlag, [Status], [Global], [Session])
EXEC ('DBCC TRACESTATUS(-1) WITH NO_INFOMSGS')

/* Disk Stats */
CREATE TABLE #DRIVES ([DriveLetter] NVARCHAR(5),[FreeSpace] BIGINT, ClusterShare BIT)

INSERT INTO #DRIVES (DriveLetter,Freespace)
EXEC master..xp_fixeddrives

IF @ISClustered = 'Yes'
BEGIN
UPDATE #DRIVES
SET ClusterShare = 0

UPDATE #DRIVES
SET ClusterShare = 1
WHERE DriveLetter IN (SELECT DriveName FROM sys.dm_io_cluster_shared_drives)
END

CREATE TABLE #PERFSTATS (
	PerfStatsHistoryID INT, 
	BufferCacheHitRatio NUMERIC(38,13), 
	PageLifeExpectency BIGINT, 
	BatchRequestsPerSecond BIGINT, 
	CompilationsPerSecond BIGINT, 
	ReCompilationsPerSecond BIGINT, 
	UserConnections BIGINT, 
	LockWaitsPerSecond BIGINT, 
	PageSplitsPerSecond BIGINT, 
	ProcessesBlocked BIGINT, 
	CheckpointPagesPerSecond BIGINT, 
	StatDate DATETIME
	)
	
CREATE TABLE #CPUSTATS (
	CPUStatsHistoryID INT, 
	SQLProcessPercent INT, 
	SystemIdleProcessPercent INT, 
	OtherProcessPerecnt INT, 
	DateStamp DATETIME
	)
	
CREATE TABLE #LONGQUERIES (
	DateStamp DATETIME,
	[ElapsedTime(ss)] INT,
	session_id SMALLINT, 
	[DBName] NVARCHAR(128), 
	login_name NVARCHAR(128), 
	sql_text NVARCHAR(MAX)
	)
	
CREATE TABLE #BLOCKING (
	DateStamp DATETIME,
	[DBName] NVARCHAR(128),
	Blocked_Spid SMALLINT,
	Blocking_Spid SMALLINT,
	Blocked_Login NVARCHAR(128),
	Blocked_Waittime_Seconds NUMERIC(12,2),
	Blocked_SQL_Text NVARCHAR(MAX),
	Offending_Login NVARCHAR(128),
	Offending_SQL_Text NVARCHAR(MAX)
	)

CREATE TABLE #SCHEMACHANGES (
	ObjectName NVARCHAR(128), 
	CreateDate DATETIME, 
	LoginName NVARCHAR(128), 
	ComputerName NVARCHAR(128), 
	SQLEvent NVARCHAR(255), 
	[DBName] NVARCHAR(128)
	)
	
CREATE TABLE #FILESTATS (
	[DBName] NVARCHAR(128),
	[DBID] INT,
	[FileID] INT,
	[FileName] NVARCHAR(255),
	[LogicalFileName] NVARCHAR(255),
	[VLFCount] INT,
	DriveLetter NCHAR(1),
	FileMBSize NVARCHAR(30),
	[FileMaxSize] NVARCHAR(30),
	FileGrowth NVARCHAR(30),
	FileMBUsed NVARCHAR(30),
	FileMBEmpty NVARCHAR(30),
	FilePercentEmpty NUMERIC(12,2),
	LargeLDF INT,
	[FileGroup] NVARCHAR(100),
	NumberReads NVARCHAR(30),
	KBytesRead NUMERIC(20,2),
	NumberWrites NVARCHAR(30),
	KBytesWritten NUMERIC(20,2),
	IoStallReadMS NVARCHAR(30),
	IoStallWriteMS NVARCHAR(30),
	Cum_IO_GB NUMERIC(12,2),
	IO_Percent NUMERIC(12,2)
	)
	
CREATE TABLE #JOBSTATUS (
	JobName NVARCHAR(255),
	Category NVARCHAR(255),
	[Enabled] INT,
	StartTime DATETIME,
	StopTime DATETIME,
	AvgRunTime NUMERIC(12,2),
	LastRunTime NUMERIC(12,2),
	RunTimeStatus NVARCHAR(30),
	LastRunOutcome NVARCHAR(20)
	)	

IF EXISTS (SELECT TOP 1 * FROM [dba].dbo.HealthReport)
BEGIN
	SELECT @StartDate = MAX(DateStamp) FROM [dba].dbo.HealthReport
END
ELSE BEGIN
	SELECT @StartDate = GETDATE() -1
END

SELECT @LongQueriesQueryValue = COALESCE(QueryValue,0) FROM [dba].dbo.AlertSettings WHERE Name = 'LongRunningQueries'
SELECT @BlockingQueryValue = COALESCE(QueryValue,0) FROM [dba].dbo.AlertSettings WHERE Name = 'BlockingAlert'	

IF @Recepients IS NULL
BEGIN
SELECT @Recepients = EmailList FROM [dba].dbo.AlertSettings WHERE Name = 'HealthReport'
END

IF @CC IS NULL
BEGIN
SELECT @CC = EmailList2 FROM [dba].dbo.AlertSettings WHERE Name = 'HealthReport'
END

/* PerfStats */
IF @IncludePerfStats = 1
BEGIN
	INSERT INTO #PERFSTATS (PerfStatsHistoryID, BufferCacheHitRatio, PageLifeExpectency, BatchRequestsPerSecond, CompilationsPerSecond, ReCompilationsPerSecond, 
		UserConnections, LockWaitsPerSecond, PageSplitsPerSecond, ProcessesBlocked, CheckpointPagesPerSecond, StatDate)
	SELECT PerfStatsHistoryID, BufferCacheHitRatio, PageLifeExpectency, BatchRequestsPerSecond, CompilationsPerSecond, ReCompilationsPerSecond, UserConnections, 
		LockWaitsPerSecond, PageSplitsPerSecond, ProcessesBlocked, CheckpointPagesPerSecond, StatDate
	FROM [dba].dbo.PerfStatsHistory WHERE StatDate >= GETDATE() -1
	AND DATEPART(mi,StatDate) = 0

	INSERT INTO #CPUSTATS (CPUStatsHistoryID, SQLProcessPercent, SystemIdleProcessPercent, OtherProcessPerecnt, DateStamp)
	SELECT CPUStatsHistoryID, SQLProcessPercent, SystemIdleProcessPercent, OtherProcessPerecnt, DateStamp
	FROM [dba].dbo.CPUStatsHistory WHERE DateStamp >= GETDATE() -1
	AND DATEPART(mi,DateStamp) = 0
END

/* LongQueries */
INSERT INTO #LONGQUERIES (DateStamp, [ElapsedTime(ss)], Session_ID, [DBName], Login_Name, SQL_Text)
SELECT MAX(collection_time) AS DateStamp,MAX(CAST(DATEDIFF(ss,start_time,collection_time) AS INT)) AS [ElapsedTime(ss)],Session_ID,
	[Database_Name] AS [DBName],Login_Name,SQL_Text
FROM [dba].dbo.QueryHistory
WHERE (DATEDIFF(ss,start_time,collection_time)) >= @LongQueriesQueryValue 
AND (DATEDIFF(dd,collection_time,@StartDate)) < 1
AND [Database_Name] NOT IN (SELECT [DBName] FROM [dba].dbo.DatabaseSettings WHERE LongQueryAlerts = 0)
AND sql_text NOT LIKE 'BACKUP DATABASE%'
AND sql_text NOT LIKE 'RESTORE VERIFYONLY%'
AND sql_text NOT LIKE 'ALTER INDEX%'
AND sql_text NOT LIKE 'DECLARE @BlobEater%'
AND sql_text NOT LIKE 'DBCC%'
AND sql_text NOT LIKE 'WAITFOR(RECEIVE%'
GROUP BY Session_ID, [Database_Name], Login_Name, SQL_Text

/* Blocking */
INSERT INTO #BLOCKING (DateStamp,[DBName],Blocked_Spid,Blocking_Spid,Blocked_Login,Blocked_Waittime_Seconds,Blocked_SQL_Text,Offending_Login,Offending_SQL_Text)
SELECT DateStamp,[DBName],Blocked_Spid,Blocking_Spid,Blocked_Login,Blocked_Waittime_Seconds,Blocked_SQL_Text,Offending_Login,Offending_SQL_Text
FROM [dba].dbo.BlockingHistory
WHERE DateStamp > @StartDate
AND Blocked_Waittime_Seconds >= @BlockingQueryValue

/* SchemaChanges */
CREATE TABLE #TEMP ([DBName] NVARCHAR(128), [Status] INT)

INSERT INTO #TEMP ([DBName], [Status])
SELECT [DBName], 0
FROM [dba].dbo.DatabaseSettings WHERE SchemaTracking = 1 AND [DBName] NOT LIKE 'AdventureWorks%'

SET @DBName = (SELECT TOP 1 [DBName] FROM #TEMP WHERE [Status] = 0)

WHILE @DBName IS NOT NULL
BEGIN

SET @SQL = 

'SELECT ObjectName,CreateDate,LoginName,ComputerName,SQLEvent,[DBName]
FROM '+ '[' + @DBName + ']' +'.dbo.SchemaChangeLog
WHERE CreateDate >'''+CONVERT(NVARCHAR(30),@StartDate,121)+'''
AND SQLEvent <> ''UPDATE_STATISTICS''
ORDER BY CreateDate DESC'

INSERT INTO #SCHEMACHANGES (ObjectName,CreateDate,LoginName,ComputerName,SQLEvent,[DBName])
EXEC(@SQL)

UPDATE #TEMP
SET [Status] = 1
WHERE [DBName] = @DBName

SET @DBName = (SELECT TOP 1 [DBName] FROM #TEMP WHERE [Status] = 0)

END
DROP TABLE #TEMP

/* FileStats */
CREATE TABLE #LOGSPACE (
	[DBName] NVARCHAR(128) NOT NULL,
	[LogSize] NUMERIC(12,2) NOT NULL,
	[LogPercentUsed] NUMERIC(12,2) NOT NULL,
	[LogStatus] INT NOT NULL
	)

CREATE TABLE #DATASPACE (
	[DBName] NVARCHAR(128) NULL,
	[Fileid] INT NOT NULL,
	[FileGroup] INT NOT NULL,
	[TotalExtents] NUMERIC(12,2) NOT NULL,
	[UsedExtents] NUMERIC(12,2) NOT NULL,
	[FileLogicalName] NVARCHAR(128) NULL,
	[Filename] NVARCHAR(255) NOT NULL
	)

CREATE TABLE #TMP_DB (
	[DBName] NVARCHAR(128)
	) 

SET @SQL = 'DBCC SQLPERF (LOGSPACE) WITH NO_INFOMSGS' 

INSERT INTO #LOGSPACE ([DBName],LogSize,LogPercentUsed,LogStatus)
EXEC(@SQL)

CREATE INDEX IDX_tLogSpace_Database ON #LOGSPACE ([DBName])

INSERT INTO #TMP_DB 
SELECT LTRIM(RTRIM(name)) AS [DBName]
FROM master..sysdatabases 
WHERE category IN ('0', '1','16')
AND DATABASEPROPERTYEX(name,'STATUS')='ONLINE'
ORDER BY name

CREATE INDEX IDX_TMPDB_Database ON #TMP_DB ([DBName])

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB)

WHILE @DBName IS NOT NULL 
BEGIN

SET @SQL = 'USE ' + '[' +@DBName + ']' + '
DBCC SHOWFILESTATS WITH NO_INFOMSGS'

INSERT INTO #DATASPACE ([Fileid],[FileGroup],[TotalExtents],[UsedExtents],[FileLogicalName],[Filename])
EXEC (@SQL)

UPDATE #DATASPACE
SET [DBName] = @DBName
WHERE COALESCE([DBName],'') = ''

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB WHERE [DBName] > @DBName)

END

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB)

WHILE @DBName IS NOT NULL 
BEGIN
 
SET @SQL = 'USE ' + '[' +@DBName + ']' + '
INSERT INTO #FILESTATS (
	[DBName],
	[DBID],
	[FileID],	
	[DriveLetter],
	[Filename],
	[LogicalFileName],
	[Filegroup],
	[FileMBSize],
	[FileMaxSize],
	[FileGrowth],
	[FileMBUsed],
	[FileMBEmpty],
	[FilePercentEmpty])
SELECT	DBName = ''' + '[' + @dbname + ']' + ''',
		DB_ID() AS [DBID],
		SF.FileID AS [FileID],
		LEFT(SF.[FileName], 1) AS DriveLetter,		
		LTRIM(RTRIM(REVERSE(SUBSTRING(REVERSE(SF.[Filename]),0,CHARINDEX(''\'',REVERSE(SF.[Filename]),0))))) AS [Filename],
		SF.name AS LogicalFileName,
		COALESCE(filegroup_name(SF.groupid),'''') AS [Filegroup],
		CAST((SF.size * 8)/1024 AS NVARCHAR) AS [FileMBSize], 
		CASE SF.maxsize 
			WHEN -1 THEN N''Unlimited'' 
			ELSE CONVERT(NVARCHAR(15), (CAST(SF.maxsize AS BIGINT) * 8)/1024) + N'' MB'' 
			END AS FileMaxSize, 
		(CASE WHEN SF.[status] & 0x100000 = 0 THEN CONVERT(NVARCHAR,CEILING((growth * 8192)/(1024.0*1024.0))) + '' MB''
			ELSE CONVERT (NVARCHAR, growth) + '' %'' 
			END) AS FileGrowth,
		CAST(COALESCE(((DSP.UsedExtents * 64.00) / 1024), LSP.LogSize *(LSP.LogPercentUsed/100)) AS BIGINT) AS [FileMBUsed],
		(SF.size * 8)/1024 - CAST(COALESCE(((DSP.UsedExtents * 64.00) / 1024), LSP.LogSize *(LSP.LogPercentUsed/100)) AS BIGINT) AS [FileMBEmpty],
		(CAST(((SF.size * 8)/1024 - CAST(COALESCE(((DSP.UsedExtents * 64.00) / 1024), LSP.LogSize *(LSP.LogPercentUsed/100)) AS BIGINT)) AS DECIMAL) / 
			CAST(CASE WHEN COALESCE((SF.size * 8)/1024,0) = 0 THEN 1 ELSE (SF.size * 8)/1024 END AS DECIMAL)) * 100 AS [FilePercentEmpty]			
FROM sys.sysfiles SF
JOIN master..sysdatabases SDB
	ON db_id() = SDB.[dbid]
JOIN sys.dm_io_virtual_file_stats(NULL,NULL) b
	ON db_id() = b.[database_id] AND SF.fileid = b.[file_id]
LEFT OUTER 
JOIN #DATASPACE DSP
	ON DSP.[Filename] COLLATE DATABASE_DEFAULT = SF.[Filename] COLLATE DATABASE_DEFAULT
LEFT OUTER 
JOIN #LOGSPACE LSP
	ON LSP.[DBName] = SDB.Name
GROUP BY SDB.Name,SF.FileID,SF.[FileName],SF.name,SF.groupid,SF.size,SF.maxsize,SF.[status],growth,DSP.UsedExtents,LSP.LogSize,LSP.LogPercentUsed'

EXEC(@SQL)

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB WHERE [DBName] > @DBName)
END

DROP TABLE #LOGSPACE
DROP TABLE #DATASPACE

UPDATE f
SET f.NumberReads = b.num_of_reads,
	f.KBytesRead = b.num_of_bytes_read / 1024,
	f.NumberWrites = b.num_of_writes,
	f.KBytesWritten = b.num_of_bytes_written / 1024,
	f.IoStallReadMS = b.io_stall_read_ms,
	f.IoStallWriteMS = b.io_stall_write_ms,
	f.Cum_IO_GB = b.CumIOGB,
	f.IO_Percent = b.IOPercent
FROM #FILESTATS f
JOIN (SELECT database_ID, [file_id], num_of_reads, num_of_bytes_read, num_of_writes, num_of_bytes_written, io_stall_read_ms, io_stall_write_ms, 
			CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576 AS DECIMAL(12, 2)) / 1024 AS CumIOGB,
			CAST(CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576 AS DECIMAL(12, 2)) / 1024 / 
				SUM(CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576 AS DECIMAL(12, 2)) / 1024) OVER() * 100 AS DECIMAL(5, 2)) AS IOPercent
		FROM sys.dm_io_virtual_file_stats(NULL,NULL)
		GROUP BY database_id, [file_id],num_of_reads, num_of_bytes_read, num_of_writes, num_of_bytes_written, io_stall_read_ms, io_stall_write_ms) AS b
ON f.[DBID] = b.[database_id] AND f.fileid = b.[file_id]

UPDATE b
SET b.LargeLDF = 
	CASE WHEN CAST(b.FileMBSize AS INT) > CAST(a.FileMBSize AS INT) THEN 1
	ELSE 2 
	END
FROM #FILESTATS a
JOIN #FILESTATS b
ON a.[DBName] = b.[DBName] 
AND a.[FileName] LIKE '%mdf' 
AND b.[FileName] LIKE '%ldf'

/* VLF INFO - USES SAME TMP_DB TO GATHER STATS */
CREATE TABLE #VLFINFO (
	[DBName] NVARCHAR(128) NULL,
	RecoveryUnitId NVARCHAR(3),
	FileID NVARCHAR(3), 
	FileSize NUMERIC(20,0),
	StartOffset BIGINT, 
	FSeqNo BIGINT, 
	[Status] CHAR(1),
	Parity NVARCHAR(4),
	CreateLSN NUMERIC(25,0)
	)

IF CAST(@SQLVer AS NUMERIC(4,2)) < 11
BEGIN
-- (SQL 2008R2 And Below)
SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB)

WHILE @DBName IS NOT NULL 
BEGIN

SET @SQL = 'USE ' + '[' +@DBName + ']' + '
INSERT INTO #VLFINFO (FileID,FileSize,StartOffset,FSeqNo,[Status],Parity,CreateLSN)
EXEC(''DBCC LOGINFO WITH NO_INFOMSGS'');'
EXEC(@SQL)

SET @SQL = 'UPDATE #VLFINFO SET DBName = ''' +@DBName+ ''' WHERE DBName IS NULL;'
EXEC(@SQL)

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB WHERE [DBName] > @DBName)
END
END
ELSE BEGIN
-- (SQL 2012 And Above)
SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB)

WHILE @DBName IS NOT NULL 
BEGIN
 
SET @SQL = 'USE ' + '[' +@DBName + ']' + '
INSERT INTO #VLFINFO (RecoveryUnitID, FileID,FileSize,StartOffset,FSeqNo,[Status],Parity,CreateLSN)
EXEC(''DBCC LOGINFO WITH NO_INFOMSGS'');'
EXEC(@SQL)

SET @SQL = 'UPDATE #VLFINFO SET DBName = ''' +@DBName+ ''' WHERE DBName IS NULL;'
EXEC(@SQL)

SET @DBName = (SELECT MIN([DBName]) FROM #TMP_DB WHERE [DBName] > @DBName)
END
END

DROP TABLE #TMP_DB

UPDATE a
SET a.VLFCount = (SELECT COUNT(1) FROM #VLFINFO WHERE [DBName] = REPLACE(REPLACE(a.DBName,'[',''),']',''))
FROM #FILESTATS a
WHERE COALESCE(a.[FileGroup],'') = ''

SELECT @MinFileStatsDateStamp = FileStatsDateStamp FROM [dba].dbo.FileStatsHistory WHERE FileStatsDateStamp <= DateAdd(hh, -24, GETDATE())

UPDATE c
SET c.NumberReads = d.NumberReads,
	c.KBytesRead = d.KBytesRead,
	c.NumberWrites = d.NumberWrites,
	c.KBytesWritten = d.KBytesWritten,
	c.IoStallReadMS = d.IoStallReadMS,
	c.IoStallWriteMS = d.IoStallWriteMS,
	c.Cum_IO_GB = d.Cum_IO_GB
FROM #FILESTATS c
LEFT OUTER
JOIN (SELECT
		b.dbname,
		b.[FileName],
		SUM(CAST(b.NumberReads AS INT) - CAST(a.NumberReads AS INT)) AS NumberReads,
		SUM(b.KBytesRead - a.KBytesRead) AS KBytesRead,
		SUM(CAST(b.NumberWrites AS INT) - CAST(a.NumberWrites AS INT)) AS NumberWrites,
		SUM(b.KBytesWritten - a.KBytesWritten) AS KBytesWritten,
		SUM(CAST(b.IoStallReadMS AS INT) - CAST(a.IoStallReadMS AS INT)) AS IoStallReadMS,
		SUM(CAST(b.IoStallWriteMS AS INT) - CAST(a.IoStallWriteMS AS INT)) AS IoStallWriteMS,
		SUM(b.Cum_IO_GB - a.Cum_IO_GB) AS Cum_IO_GB
		FROM [dba].dbo.FileStatsHistory a
		LEFT OUTER
		JOIN #FILESTATS b
			ON a.dbname = b.dbname 
			AND a.[FileName] = b.[FileName]
		WHERE a.FileStatsDateStamp = @MinFileStatsDateStamp
		GROUP BY b.DBName,b.[FileName]) d
	ON c.dbname = d.dbname 
	AND c.[FileName] = d.[FileName]

/* JobStats */
SELECT sj.job_id, 
		sj.name,
		sc.name AS Category,
		sj.[Enabled], 
		sjs.last_run_outcome,
		(SELECT MAX(run_date) 
			FROM msdb..sysjobhistory(nolock) sjh 
			WHERE sjh.job_id = sj.job_id) AS last_run_date
INTO #TEMPJOB
FROM msdb..sysjobs(nolock) sj
JOIN msdb..sysjobservers(nolock) sjs
	ON sjs.job_id = sj.job_id
JOIN msdb..syscategories sc
	ON sj.category_id = sc.category_id	

INSERT INTO #JOBSTATUS (JobName,Category,[Enabled],StartTime,StopTime,AvgRunTime,LastRunTime,RunTimeStatus,LastRunOutcome)
SELECT
	t.name AS JobName,
	t.Category,
	t.[Enabled],
	MAX(ja.start_execution_date) AS [StartTime],
	MAX(ja.stop_execution_date) AS [StopTime],
	COALESCE(AvgRunTime,0) AS AvgRunTime,
	CASE 
		WHEN ja.stop_execution_date IS NULL THEN COALESCE(DATEDIFF(ss,ja.start_execution_date,GETDATE()),0)
		ELSE DATEDIFF(ss,ja.start_execution_date,ja.stop_execution_date) END AS [LastRunTime],
	CASE 
			WHEN ja.stop_execution_date IS NULL AND ja.start_execution_date IS NOT NULL THEN
				CASE WHEN DATEDIFF(ss,ja.start_execution_date,GETDATE())
					> (AvgRunTime + AvgRunTime * .25) THEN 'LongRunning-NOW'				
				ELSE 'NormalRunning-NOW'
				END
			WHEN DATEDIFF(ss,ja.start_execution_date,ja.stop_execution_date) 
				> (AvgRunTime + AvgRunTime * .25) THEN 'LongRunning-History'
			WHEN ja.stop_execution_date IS NULL AND ja.start_execution_date IS NULL THEN 'NA'
			ELSE 'NormalRunning-History'
	END AS [RunTimeStatus],	
	CASE
		WHEN ja.stop_execution_date IS NULL AND ja.start_execution_date IS NOT NULL THEN 'InProcess'
		WHEN ja.stop_execution_date IS NOT NULL AND t.last_run_outcome = 3 THEN 'CANCELLED'
		WHEN ja.stop_execution_date IS NOT NULL AND t.last_run_outcome = 0 THEN 'ERROR'			
		WHEN ja.stop_execution_date IS NOT NULL AND t.last_run_outcome = 1 THEN 'SUCCESS'			
		ELSE 'NA'
	END AS [LastRunOutcome]
FROM #TEMPJOB AS t
LEFT OUTER
JOIN (SELECT MAX(session_id) as session_id,job_id FROM msdb.dbo.sysjobactivity(nolock) WHERE run_requested_date IS NOT NULL GROUP BY job_id) AS ja2
	ON t.job_id = ja2.job_id
LEFT OUTER
JOIN msdb.dbo.sysjobactivity(nolock) ja
	ON ja.session_id = ja2.session_id and ja.job_id = t.job_id
LEFT OUTER 
JOIN (SELECT job_id,
			AVG	((run_duration/10000 * 3600) + ((run_duration%10000)/100*60) + (run_duration%10000)%100) + 	STDEV ((run_duration/10000 * 3600) + 
				((run_duration%10000)/100*60) + (run_duration%10000)%100) AS [AvgRuntime]
		FROM msdb..sysjobhistory(nolock)
		WHERE step_id = 0 AND run_status = 1 and run_duration >= 0
		GROUP BY job_id) art 
	ON t.job_id = art.job_id
GROUP BY t.name,t.Category,t.[Enabled],t.last_run_outcome,ja.start_execution_date,ja.stop_execution_date,AvgRunTime
ORDER BY t.name

DROP TABLE #TEMPJOB

/* Replication Distributor */
CREATE TABLE #REPLINFO (
	distributor NVARCHAR(128) NULL, 
	[distribution database] NVARCHAR(128) NULL, 
	directory NVARCHAR(500), 
	account NVARCHAR(200), 
	[min distrib retention] INT, 
	[max distrib retention] INT, 
	[history retention] INT,
	[history cleanup agent] NVARCHAR(500),
	[distribution cleanup agent] NVARCHAR(500),
	[rpc server name] NVARCHAR(200),
	[rpc login name] NVARCHAR(200),
	publisher_type NVARCHAR(200)
	)

INSERT INTO #REPLINFO
EXEC sp_helpdistributor

/* Replication Publisher */	
CREATE TABLE #PUBINFO (
	publisher_db NVARCHAR(128),
	publication NVARCHAR(128),
	publication_id INT,
	publication_type INT,
	[status] INT,
	warning INT,
	worst_latency INT,
	best_latency INT,
	average_latency INT,
	last_distsync DATETIME,
	[retention] INT,
	latencythreshold INT,
	expirationthreshold INT,
	agentnotrunningthreshold INT,
	subscriptioncount INT,
	runningdisagentcount INT,
	snapshot_agentname NVARCHAR(128) NULL,
	logreader_agentname NVARCHAR(128) NULL,
	qreader_agentname NVARCHAR(128) NULL,
	worst_runspeedPerf INT,
	best_runspeedPerf INT,
	average_runspeedPerf INT,
	retention_period_unit INT
	)
	
SELECT @Distributor = distributor, @DistributionDB = [distribution database] FROM #REPLINFO

IF @Distributor = @@SERVERNAME
BEGIN

SET @DistSQL = 
'USE ' + @DistributionDB + '; EXEC sp_replmonitorhelppublication @@SERVERNAME

INSERT 
INTO #PUBINFO
EXEC sp_replmonitorhelppublication @@SERVERNAME'

EXEC(@DistSQL)

END

/* Replication Subscriber */
CREATE TABLE #REPLSUB (
	Publisher NVARCHAR(128),
	Publisher_DB NVARCHAR(128),
	Publication NVARCHAR(128),
	Distribution_Agent NVARCHAR(128),
	[Time] DATETIME,
	Immediate_Sync BIT
	)

INSERT INTO #REPLSUB
EXEC master.sys.sp_MSForEachDB 'USE [?]; 
								IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE Table_Name = ''MSreplication_subscriptions'') 
								BEGIN 
								SELECT Publisher,Publisher_DB,Publication,Distribution_Agent,[time],immediate_sync FROM MSreplication_subscriptions 
								END'

/* Databases */
CREATE TABLE #DATABASES (
	[DBName] NVARCHAR(128),
	CreateDate DATETIME,
	RestoreDate DATETIME,
	[Size(GB] NUMERIC(20,5),
	[State] NVARCHAR(20),
	[Recovery] NVARCHAR(20),
	[Replication] NVARCHAR(5) DEFAULT('No'),
	Mirroring NVARCHAR(5) DEFAULT('No')
	)

INSERT INTO #DATABASES ([DBName],CreateDate,RestoreDate,[Size(GB],[State],[Recovery])
SELECT MST.Name,MST.create_date,rs.RestoreDate,SUM(CONVERT(DECIMAL,(f.FileMBSize)) / 1024) AS [Size(GB],MST.state_desc,MST.recovery_model_desc
FROM sys.databases MST
JOIN #FILESTATS F
	ON MST.database_id = f.[dbID]
LEFT OUTER
JOIN (SELECT destination_database_name AS DBName,
		MAX(restore_date) AS RestoreDate
		FROM msdb..restorehistory
		GROUP BY destination_database_name) AS rs
	ON MST.Name = rs.DBName	
GROUP BY MST.Name,MST.create_date,rs.RestoreDate,MST.state_desc,MST.recovery_model_desc

UPDATE d
SET d.Mirroring = 'Yes'
FROM #Databases d
JOIN master..sysdatabases a
	ON d.[DBName] = a.Name
JOIN sys.database_mirroring b
	ON b.database_id = a.[dbid]
WHERE b.mirroring_state IS NOT NULL

UPDATE d
SET d.[Replication] = 'Yes'
FROM #Databases d
JOIN #REPLSUB r
	ON d.[DBName] = r.Publication

UPDATE d
SET d.[Replication] = 'Yes'
FROM #Databases d
JOIN #PUBINFO p
	ON d.[DBName] = p.Publisher_DB

UPDATE d
SET d.[Replication] = 'Yes'
FROM #Databases d
JOIN #REPLINFO r
	ON d.[DBName] = r.[distribution database]

/* LogShipping */
SELECT b.primary_server, b.primary_database, a.monitor_server, c.secondary_server, c.secondary_database, a.last_backup_date, a.last_backup_file, backup_share
INTO #LOGSHIP
FROM msdb..log_shipping_primary_databases a
JOIN  msdb..log_shipping_monitor_primary b
	ON a.primary_id = b.primary_id
JOIN msdb..log_shipping_primary_secondaries c
	ON a.primary_id = c.primary_id

/* Mirroring */

CREATE TABLE #MIRRORING (
	[DBName] NVARCHAR(128),
	[State] NVARCHAR(50),
	[ServerRole] NVARCHAR(25),
	[PartnerInstance] NVARCHAR(128),
	[SafetyLevel] NVARCHAR(25),
	[AutomaticFailover] NVARCHAR(5),
	WitnessServer NVARCHAR(5)
	)

INSERT INTO #MIRRORING ([DBName], [State], [ServerRole], [PartnerInstance], [SafetyLevel], [AutomaticFailover], [WitnessServer])
SELECT s.name AS [DBName], 
	m.mirroring_state_desc AS [State], 
	m.mirroring_role_desc AS [ServerRole], 
	m.mirroring_partner_instance AS [PartnerInstance],
	CASE WHEN m.mirroring_safety_level_desc = 'FULL' THEN 'HIGH SAFETY' ELSE 'HIGH PERFORMANCE' END AS [SafetyLevel], 
	CASE WHEN m.mirroring_witness_name <> '' THEN 'Yes' ELSE 'No' END AS [AutomaticFailover],
	CASE WHEN m.mirroring_witness_name <> '' THEN m.mirroring_witness_name ELSE 'N/A' END AS [WitnessServer]
FROM master..sysdatabases s
JOIN sys.database_mirroring m
	ON s.[dbid] = m.database_id
WHERE m.mirroring_state IS NOT NULL


/* ErrorLog */
CREATE TABLE #DEADLOCKINFO (
	DeadlockDate DATETIME,
	DBName NVARCHAR(128),	
	ProcessInfo NVARCHAR(50),
	VictimHostname NVARCHAR(128),
	VictimLogin NVARCHAR(128),	
	VictimSPID NVARCHAR(5),
	VictimSQL NVARCHAR(500),
	LockingHostname NVARCHAR(128),
	LockingLogin NVARCHAR(128),
	LockingSPID NVARCHAR(5),
	LockingSQL NVARCHAR(500)
	)

CREATE TABLE #ERRORLOG (
	ID INT IDENTITY(1,1) NOT NULL
		CONSTRAINT PK_ERRORLOGTEMP
			PRIMARY KEY CLUSTERED (ID),
	LogDate DATETIME, 
	ProcessInfo NVARCHAR(100), 
	[Text] NVARCHAR(4000)
	)
	
CREATE TABLE #TEMPDATES (LogDate DATETIME)

INSERT INTO #ERRORLOG
EXEC sp_readerrorlog 0, 1

IF EXISTS (SELECT * FROM #TRACESTATUS WHERE TraceFlag = 1222)
BEGIN
INSERT INTO #TEMPDATES (LogDate)
SELECT DISTINCT CONVERT(VARCHAR(30),LogDate,120) as LogDate
FROM #ERRORLOG
WHERE ProcessInfo LIKE 'spid%'
and [text] LIKE '   process id=%'

INSERT INTO #DEADLOCKINFO (DeadLockDate, DBName, ProcessInfo, VictimHostname, VictimLogin, VictimSPID, LockingHostname, LockingLogin, LockingSPID)
SELECT 
DISTINCT CONVERT(VARCHAR(30),b.LogDate,120) AS DeadlockDate,
DB_NAME(SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%currentdb=%',b.[text]),SUM((PATINDEX('%lockTimeout%',b.[text])) - (PATINDEX('%currentdb=%',b.[text])) ) )),11,50)) as DBName,
b.processinfo,
SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%hostname=%',a.[text]),SUM((PATINDEX('%hostpid%',a.[text])) - (PATINDEX('%hostname=%',a.[text])) ) )),10,50)
	AS VictimHostname,
CASE WHEN SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%loginname=%',a.[text]),SUM((PATINDEX('%isolationlevel%',a.[text])) - (PATINDEX('%loginname=%',a.[text])) ) )),11,50) NOT LIKE '%id%'
	THEN SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%loginname=%',a.[text]),SUM((PATINDEX('%isolationlevel%',a.[text])) - (PATINDEX('%loginname=%',a.[text])) ) )),11,50)
	ELSE NULL END AS VictimLogin,
CASE WHEN SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%spid=%',a.[text]),SUM((PATINDEX('%sbid%',a.[text])) - (PATINDEX('%spid=%',a.[text])) ) )),6,10) NOT LIKE '%id%'
	THEN SUBSTRING(RTRIM(SUBSTRING(a.[text],PATINDEX('%spid=%',a.[text]),SUM((PATINDEX('%sbid%',a.[text])) - (PATINDEX('%spid=%',a.[text])) ) )),6,10)
	ELSE NULL END AS VictimSPID,
SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%hostname=%',b.[text]),SUM((PATINDEX('%hostpid%',b.[text])) - (PATINDEX('%hostname=%',b.[text])) ) )),10,50)
	AS LockingHostname,
CASE WHEN SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%loginname=%',b.[text]),SUM((PATINDEX('%isolationlevel%',b.[text])) - (PATINDEX('%loginname=%',b.[text])) ) )),11,50) NOT LIKE '%id%'
	THEN SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%loginname=%',b.[text]),SUM((PATINDEX('%isolationlevel%',b.[text])) - (PATINDEX('%loginname=%',b.[text])) ) )),11,50)
	ELSE NULL END AS LockingLogin,
CASE WHEN SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%spid=%',b.[text]),SUM((PATINDEX('%sbid=%',b.[text])) - (PATINDEX('%spid=%',b.[text])) ) )),6,10) NOT LIKE '%id%'
	THEN SUBSTRING(RTRIM(SUBSTRING(b.[text],PATINDEX('%spid=%',b.[text]),SUM((PATINDEX('%sbid=%',b.[text])) - (PATINDEX('%spid=%',b.[text])) ) )),6,10)
	ELSE NULL END AS LockingSPID
FROM #TEMPDATES t
JOIN #ERRORLOG a
	ON CONVERT(VARCHAR(30),t.LogDate,120) = CONVERT(VARCHAR(30),a.LogDate,120)
JOIN #ERRORLOG b
	ON CONVERT(VARCHAR(30),t.LogDate,120) = CONVERT(VARCHAR(30),b.LogDate,120) AND a.[text] LIKE '   process id=%' AND b.[text] LIKE '   process id=%' AND a.ID < b.ID 
GROUP BY b.LogDate,b.processinfo, a.[Text], b.[Text]

DELETE FROM #ERRORLOG
WHERE CONVERT(VARCHAR(30),LogDate,120) IN (SELECT DeadlockDate FROM #DEADLOCKINFO)

DELETE FROM #DEADLOCKINFO
WHERE (DeadlockDate <  CONVERT(DATETIME, CONVERT (VARCHAR(10), GETDATE(), 101)) -1)
OR (DeadlockDate >= CONVERT(DATETIME, CONVERT (VARCHAR(10), GETDATE(), 101)))

END

DELETE FROM #ERRORLOG
WHERE LogDate < (GETDATE() -1)
OR ProcessInfo = 'Backup'

/* BackupStats */
CREATE TABLE #BACKUPS (
	ID INT IDENTITY(1,1) NOT NULL
		CONSTRAINT PK_BACKUPS
			PRIMARY KEY CLUSTERED (ID),
	[DBName] NVARCHAR(128),
	[Type] NVARCHAR(50),
	[Filename] NVARCHAR(128),
	Backup_Set_Name NVARCHAR(128),
	Backup_Start_Date DATETIME,
	Backup_Finish_Date DATETIME,
	Backup_Size NUMERIC(20,2),
	Backup_Age INT
	)

INSERT INTO #BACKUPS ([DBName],[Type],[Filename],Backup_Set_Name,backup_start_date,backup_finish_date,backup_size,backup_age)
SELECT a.database_name AS [DBName],
		CASE a.[Type]
		WHEN 'D' THEN 'Full'
		WHEN 'I' THEN 'Diff'
		WHEN 'L' THEN 'Log'
		WHEN 'F' THEN 'File/Filegroup'
		WHEN 'G' THEN 'File Diff'
		WHEN 'P' THEN 'Partial'
		WHEN 'Q' THEN 'Partial Diff'
		ELSE 'Unknown' END AS [Type],
		COALESCE(b.Physical_Device_Name,'N/A') AS [Filename],
		a.name AS Backup_Set_Name,		
		a.backup_start_date,
		a.backup_finish_date,
		CAST((a.backup_size/1024)/1024/1024 AS DECIMAL(10,2)) AS Backup_Size,
		DATEDIFF(hh, MAX(a.backup_finish_date), GETDATE()) AS [Backup_Age] 
FROM msdb..backupset a
JOIN msdb..backupmediafamily b
	ON a.media_set_id = b.media_set_id
WHERE a.backup_start_date > GETDATE() -1
GROUP BY a.database_name, a.[Type],a.name, b.Physical_Device_Name,a.backup_start_date,a.backup_finish_date,a.backup_size

/* STEP 2: CREATE HTML BLOB */

SET @HTML =    
	'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"><html><head><style type="text/css">
	table { border: 0px; border-spacing: 0px; border-collapse: collapse;}
	th {color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;border: 0;}
	th.header {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;border-top-left-radius: 15px 10px; 
		border-top-right-radius: 15px 10px;}  
	td {font-size:11px; font-family:arial;border-right: 0;border-bottom: 1px solid #C1DAD7;padding: 5px 5px 5px 8px;}
	td.c2 {background-color: #F0F0F0}
	td.c1 {background-color: #E0E0E0}
	td.master {border-bottom:0px}
	.Perfth {text-align:center; vertical-align:bottom; color:#FFFFFF; font-size:12px; font-family:arial; background-color:#7394B0; font-weight:bold;
		border-right: 1px solid #41627E; padding: 3px 3px 3px 3px;}
	.Perfthheader {color:#FFFFFF; font-size:13px; font-family:arial; background-color:#41627E; font-weight:bold;border: 0;border-top-left-radius: 15px 10px; 
		border-top-right-radius: 15px 10px;}  
	.Perftd {text-align:center; vertical-align:bottom; font-size:9px; font-family:arial;border-right: 1px solid #C1DAD7;border-bottom: 1px solid #C1DAD7;
		padding: 3px 1px 3px 1px;}
	.Text {background-color: #E0E0E0}
	.Text2 {background-color: #F0F0F0}	
	.Alert {background-color: #FF0000}
	.Warning {background-color: #FFFF00} 	
	</style></head><body><div>
	<table width="1150"> <tr><th class="header" width="1150">System</th></tr></table></div><div>
	<table width="1150">
	<tr>
	<th width="200">Name</th>
	<th width="300">Processor</th>	
	<th width="250">Operating System</th>	
	<th width="125">Total Memory (GB)</th>
	<th width="200">Uptime</th>
	<th width="75">Clustered</th>	
	</tr>'
SELECT @HTML = @HTML + 
	'<tr><td width="200" class="c1">'+@ServerName +'</td>' +
	'<td width="300" class="c2">'+@Processor +'</td>' +
	'<td width="250" class="c1">'+@ServerOS +'</td>' +
	'<td width="125" class="c2">'+@SystemMemory+'</td>' +	
	'<td width="200" class="c1">'+@Days+' days, '+@Hours+' hours & '+@Minutes+' minutes' +'</td>' +
	'<td width="75" class="c2"><b>'+@ISClustered+'</b></td></tr>'
SELECT @HTML = @HTML + 	'</table></div>'

SELECT @HTML = @HTML + 
'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">SQL Server</th></tr></table></div><div>
	<table width="1150">
	<tr>
	<th width="350">Version</th>	
	<th width="150">Start Up Date</th>
	<th width="100">Used Memory (MB)</th>
	<th width="100">Collation</th>
	<th width="75">User Mode</th>
	<th width="75">SQL Agent</th>	
	</tr>'
SELECT @HTML = @HTML + 
	'<tr><td width="350" class="c1">'+@SQLVersion +'</td>' +
	'<td width="150" class="c2">'+CAST(@ServerStartDate AS NVARCHAR)+'</td>' +
	'<td width="100" class="c1">'+CAST(@ServerMemory AS NVARCHAR)+'</td>' +
	'<td width="100" class="c2">'+@ServerCollation+'</td>' +
	CASE WHEN @SingleUser = 'Multi' THEN '<td width="75" class="c1"><b>Multi</b></td>'  
		 WHEN @SingleUser = 'Single' THEN '<td width="75" bgcolor="#FFFF00"><b>Single</b></td>'
	ELSE '<td width="75" bgcolor="#FF0000"><b>UNKNOWN</b></td>'
	END +	
	CASE WHEN @SQLAgent = 'Up' THEN '<td width="75" bgcolor="#00FF00"><b>Up</b></td></tr>'  
		 WHEN @SQLAgent = 'Down' THEN '<td width="75" bgcolor="#FF0000"><b>DOWN</b></td></tr>'  
	ELSE '<td width="75" bgcolor="#FF0000"><b>UNKNOWN</b></td></tr>'  
	END

SELECT @HTML = @HTML + '</table></div>'

SELECT @HTML = @HTML +
'&nbsp;<table width="1150"><tr><td class="master" width="850" rowspan="3">
	<div><table width="850"> <tr><th class="header" width="850">Databases</th></tr></table></div><div>
	<table width="850">
	  <tr>
		<th width="175">Database</th>
		<th width="150">Create Date</th>
		<th width="150">Restore Date</th>
		<th width="80">Size (GB)</th>
		<th width="70">State</th>
		<th width="75">Recovery</th>
		<th width="75">Replicated</th>
		<th width="75">Mirrored</th>				
	 </tr>'
SELECT @HTML = @HTML +   
	'<tr><td width="175" class="c1">' + [DBName] +'</td>' +
	'<td width="150" class="c2">' + CAST(CreateDate AS NVARCHAR) +'</td>' +
	'<td width="150" class="c1">' + COALESCE(CAST(RestoreDate AS NVARCHAR),'N/A') +'</td>' +   	 
	'<td width="80" class="c2">' + CAST([Size(GB] AS NVARCHAR) +'</td>' +    
 	CASE [State]    
		WHEN 'OFFLINE' THEN '<td width="70" bgColor="#FF0000"><b>OFFLINE</b></td>'
		WHEN 'ONLINE' THEN '<td width="70" class="c1">ONLINE</td>'  
	ELSE '<td width="70" bgcolor="#FF0000"><b>UNKNOWN</b></td>'
	END +
	'<td width="75" class="c2">' + [Recovery] +'</td>' +
	'<td width="75" class="c1">' + [Replication] +'</td>' +
	'<td width="75" class="c2">' + Mirroring +'</td></tr>'		
FROM #DATABASES
ORDER BY [DBName]

SELECT @HTML = @HTML + '</table></div>'

SELECT @HTML = @HTML + '</td><td class="master" width="250" valign="top">'

SELECT @HTML = @HTML + 
	'<div><table width="250"> <tr><th class="header" width="250">Disks</th></tr></table></div><div>
	<table width="250">
	  <tr>
		<th width="50">Drive</th>
		<th width="100">Free Space (GB)</th>
		<th width="100">Cluster Share</th>		
	 </tr>'
SELECT @HTML = @HTML +   
	'<tr><td width="50" class="c1">' + DriveLetter + ':' +'</td>' +    
	CASE  
		WHEN (COALESCE(CAST(CAST(FreeSpace AS DECIMAL(10,2))/1024 AS DECIMAL(10,2)), 0) <= 20) 
			THEN '<td width="100" bgcolor="#FF0000"><b>' + COALESCE(CONVERT(NVARCHAR(50), COALESCE(CAST(CAST(FreeSpace AS DECIMAL(10,2))/1024 AS DECIMAL(10,2)), 0)),'') +'</b></td>'
		ELSE '<td width="100" class="c2">' + COALESCE(CONVERT(NVARCHAR(50), COALESCE(CAST(CAST(FreeSpace AS DECIMAL(10,2))/1024 AS DECIMAL(10,2)), 0)),'') +'</td>' 
		END +
	CASE ClusterShare
		WHEN 1 THEN '<td width="100" class="c1">Yes</td></tr>'
		WHEN 0 THEN '<td width="100" class="c1">No</td></tr>'
		ELSE '<td width="100" class="c1">N/A</td></tr>'
		END
FROM #DRIVES

SELECT @HTML = @HTML + '</table></div>'

SELECT @HTML = @HTML + '<tr><td class="master" width="250" valign="top">'

IF EXISTS (SELECT * FROM #CLUSTER)
BEGIN
SELECT @HTML = @HTML + 
	'&nbsp;<div><table width="250"> <tr><th class="header" width="250">Clustering</th></tr></table></div><div>
	<table width="250">
	  <tr>
		<th width="175">Cluster Name</th>
		<th width="75">Active</th>
	 </tr>'
SELECT @HTML = @HTML +   
	'<tr><td width="175" class="c1">' + NodeName +'</td>' +    
	CASE Active
		WHEN 1 THEN '<td width="75" class="c2">Yes</td></tr>'
		ELSE '<td width="75" class="c2">No</td></tr>'
		END
FROM #CLUSTER

SELECT @HTML = @HTML + '</table></div>'
END

SELECT @HTML = @HTML + '<tr><td class="master" width="250" valign="top">'

IF EXISTS (SELECT * FROM #TRACESTATUS)
BEGIN
SELECT @HTML = @HTML + 
	'&nbsp;<div><table width="250"> <tr><th class="header" width="250">Trace Flags</th></tr></table></div><div>
	<table width="250">
	  <tr>
		<th width="65">Trace Flag</th>
		<th width="65">Status</th>
		<th width="60">Global</th>
		<th width="60">Session</th>				
	 </tr>'
SELECT @HTML = @HTML + '<tr><td width="65" class="c1">' + CAST([TraceFlag] AS NVARCHAR) + '</td>' +    
	CASE [Status]
		WHEN 1 THEN '<td width="65" class="c2">Active</td>'
		ELSE '<td width="65" class="c2">Inactive</td>'
		END +
	CASE [Global]
		WHEN 1 THEN '<td width="60" class="c1">On</td>'
		ELSE '<td width="60" class="c1">Off</td>'
		END +
	CASE [Session]
		WHEN 1 THEN '<td width="60" class="c2">On</td></tr>'
		ELSE '<td width="60" class="c2">Off</td></tr>'
		END	
FROM #TRACESTATUS

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT @HTML = @HTML + 
	'&nbsp;<div><table width="250"> <tr><th class="header" width="250">Trace Flags</th></tr></table></div><div>
	<table width="250">
	  <tr>
		<th width="250"><b>No Trace Flags Are Active</b></th>			
	 </tr>'

SELECT @HTML = @HTML + '</table></div>'
END

SELECT @HTML = @HTML + '</td></tr></table>'

SELECT @HTML = @HTML + 
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">File Info</th></tr></table></div><div>
	<table width="1150">
	  <tr>
		<th width="150">Database</th>
		<th width="50">Drive</th>
		<th width="250">Filename</th>
		<th width="150">Logical Name</th>
		<th width="100">Group</th>
		<th width="75">VLF Count</th>
		<th width="75">Size (MB)</th>
		<th width="75">Growth</th>
		<th width="75">Used (MB)</th>
		<th width="75">Empty (MB)</th>
		<th width="75">% Empty</th>
	 </tr>'
SELECT @HTML = @HTML +
	'<tr><td width="150" class="c1">' + [DBName] +'</td>' +
	'<td width="50" class="c2">' + COALESCE(DriveLetter,'N/A') + ':' +'</td>' +
	'<td width="250" class="c1">' + [Filename] +'</td>' +
	'<td width="150" class="c2">' + [LogicalFilename] +'</td>' +	
	CASE
		WHEN COALESCE([FileGroup],'') <> '' THEN '<td width="100" class="c1">' + [FileGroup] +'</td>'
		ELSE '<td width="100" class="c1">' + 'N/A' +'</td>'
		END +
	'<td width="75" class="c2">' + CAST(COALESCE(VLFCount,'') AS NVARCHAR) +'</td>' +
	CASE
		WHEN (LargeLDF = 1 AND [FileName] LIKE '%ldf') THEN '<td width="75" bgColor="#FFFF00">' + FileMBSize +'</td>'
		ELSE '<td width="75" class="c1">' + FileMBSize +'</td>'
		END +
	'<td width="75" class="c2">' + FileGrowth +'</td>' +
	'<td width="75" class="c1">' + FileMBUsed +'</td>' +
	'<td width="75" class="c2">' + FileMBEmpty +'</td>' +
	'<td width="75" class="c1">' + CAST(FilePercentEmpty AS NVARCHAR) + '</td>' + '</tr>'
FROM #FILESTATS

SELECT @HTML = @HTML + '</table></div>'

SELECT @HTML = @HTML + 
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">File Stats - Last 24 Hours</th></tr></table></div><div>
	<table width="1150">
	  <tr>
		<th width="200">Filename</th>
		<th width="75"># Reads</th>
		<th width="175">KBytes Read</th>
		<th width="75"># Writes</th>
		<th width="175">KBytes Written</th>
		<th width="125">IO Read Wait (MS)</th>
		<th width="125">IO Write Wait (MS)</th>
		<th width="125">Cumulative IO (GB)</th>
		<th width="75">IO %</th>				
	 </tr>'
SELECT @HTML = @HTML +
	'<tr><td width="200" class="c1">' + [FileName] +'</td>' +
	'<td width="75" class="c2">' + COALESCE(NumberReads,'0') +'</td>' +
	'<td width="175" class="c1">' + COALESCE(CONVERT(NVARCHAR(50), KBytesRead),'') + ' (' + COALESCE(CONVERT(NVARCHAR(50), CAST(KBytesRead / 1024 AS NUMERIC(18,2))),'') +
		  ' MB)' +'</td>' +
	'<td width="75" class="c2">' + COALESCE(NumberWrites,'0') +'</td>' +
	'<td width="175" class="c1">' + COALESCE(CONVERT(NVARCHAR(50), KBytesWritten),'') + ' (' + COALESCE(CONVERT(NVARCHAR(50), CAST(KBytesWritten / 1024 AS NUMERIC(18,2)) ),'') +
		  ' MB)' +'</td>' +
	'<td width="125" class="c2">' + COALESCE(IoStallReadMS,'0') +'</td>' +
	'<td width="125" class="c1">' + COALESCE(IoStallWriteMS,'0') + '</td>' +
	'<td width="125" class="c2">' + CAST(COALESCE(Cum_IO_GB,'0') AS VARCHAR) + '</td>' +
	'<td width="75" class="c1">' + CAST(COALESCE(IO_Percent,'0') AS VARCHAR) + '</td>' + '</tr>'	
FROM #FILESTATS

SELECT @HTML = @HTML + '</table></div>'

IF EXISTS (SELECT * FROM #MIRRORING)
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Mirroring</th></tr></table></div><div>
	<table width="1150">   
	<tr> 
	<th width="150">Database</th>      
	<th width="150">State</th>   
	<th width="150">Server Role</th>   
	<th width="150">Partner Instance</th>
	<th width="150">Safety Level</th>
	<th width="200">Automatic Failover</th>
	<th width="250">Witness Server</th>   
	</tr>'	
SELECT
	@HTML = @HTML +   
	'<tr><td width="150" class="c1">' + [DBName] +'</td>' +
	'<td width="150" class="c2">' + [State] +'</td>' +  
	'<td width="150" class="c1">' + [ServerRole] +'</td>' +  
	'<td width="150" class="c2">' + [PartnerInstance] +'</td>' +  
	'<td width="150" class="c1">' + [SafetyLevel] +'</td>' +  
	'<td width="200" class="c2">' + [AutomaticFailover] +'</td>' +  
	'<td width="250" class="c1">' + [WitnessServer] +'</td>' +  
	 '</tr>'
FROM #MIRRORING
ORDER BY [DBName]

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Mirroring</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">Mirroring is not setup on this system</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #LOGSHIP)
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Log Shipping</th></tr></table></div><div>
	<table width="1150">   
	<tr> 
	<th width="150">Primary Server</th>      
	<th width="150">Primary DB</th>   
	<th width="150">Monitoring Server</th>   
	<th width="150">Secondary Server</th>
	<th width="150">Secondary DB</th>
	<th width="200">Last Backup Date</th>
	<th width="250">Backup Share</th>   
	</tr>'
SELECT
	@HTML = @HTML +   
	'<tr><td width="150" class="c1">' + primary_server +'</td>' +
	'<td width="150" class="c2">' + primary_database +'</td>' +  
	'<td width="150" class="c1">' + monitor_server +'</td>' +  
	'<td width="150" class="c2">' + secondary_server +'</td>' +  
	'<td width="150" class="c1">' + secondary_database +'</td>' +  
	'<td width="200" class="c2">' + CAST(last_backup_date AS NVARCHAR) +'</td>' +  
	'<td width="250" class="c1">' + backup_share +'</td>' +  
	 '</tr>'
FROM #LOGSHIP
ORDER BY Primary_Database

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Log Shipping</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">Log Shipping is not setup on this system</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #REPLINFO WHERE Distributor IS NOT NULL)
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Replication Distributor</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="150">Distributor</th>      
			<th width="150">Distribution DB</th>   
			<th width="500">Replcation Share</th>   
			<th width="200">Replication Account</th>
			<th width="150">Publisher Type</th>
		</tr>'
SELECT
	@HTML = @HTML +   
	'<tr><td width="150" class="c1">' + Distributor +'</td>' +
	'<td width="150" class="c2">' + [distribution database] +'</td>' +  
	'<td width="500" class="c1">' + CAST(directory AS NVARCHAR) +'</td>' +  
	'<td width="200" class="c2">' + CAST(account AS NVARCHAR) +'</td>' +  
	'<td width="150" class="c1">' + CAST(publisher_type AS NVARCHAR) +'</td></tr>'
FROM #REPLINFO

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Replication Distributor</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">Distributor is not setup on this system</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #PUBINFO)
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Replication Publisher</th></tr></table></div><div>
	<table width="1150">   
	<tr> 
	<th width="150">Publisher DB</th>      
	<th width="150">Publication</th>   
	<th width="150">Publication Type</th>   
	<th width="75">Status</th>
	<th width="100">Warnings</th>
	<th width="125">Best Latency</th>
	<th width="125">Worst Latency</th>
	<th width="125">Average Latency</th>
	<th width="150">Last Dist Sync</th>				
	</tr>'
SELECT
	@HTML = @HTML +   
	'<tr> 
	<td width="150" class="c1">' + publisher_db +'</td>' +
	'<td width="150" class="c2">' + publication +'</td>' +  
	CASE
		WHEN publication_type = 0 THEN '<td width="150" class="c1">' + 'Transactional Publication' +'</td>'
		WHEN publication_type = 1 THEN '<td width="150" class="c1">' + 'Snapshot Publication' +'</td>'
		WHEN publication_type = 2 THEN '<td width="150" class="c1">' + 'Merge Publication' +'</td>'
		ELSE '<td width="150" class="c1">' + 'N/A' +'</td>'
	END +
	CASE
		WHEN [status] = 1 THEN '<td width="75" class="c2">' + 'Started' +'</td>'
		WHEN [status] = 2 THEN '<td width="75" class="c2">' + 'Succeeded' +'</td>'
		WHEN [status] = 3 THEN '<td width="75" class="c2">' + 'In Progress' +'</td>'
		WHEN [status] = 4 THEN '<td width="75" class="c2">' + 'Idle' +'</td>'
		WHEN [status] = 5 THEN '<td width="75" class="c2">' + 'Retrying' +'</td>'
		WHEN [status] = 6 THEN '<td width="75" class="c2">' + 'Failed' +'</td>'
		ELSE '<td width="75" class="c2">' + 'N/A' +'</td>'
	END +
	CASE
		WHEN Warning = 1 THEN '<td width="100" bgcolor="#FFFF00">' + 'Expiration' +'</td>'
		WHEN Warning = 2 THEN '<td width="100" bgcolor="#FFFF00">' + 'Latency' +'</td>'
		WHEN Warning = 4 THEN '<td width="100" bgcolor="#FFFF00">' + 'Merge Expiration' +'</td>'
		WHEN Warning = 8 THEN '<td width="100" bgcolor="#FFFF00">' + 'Merge Fast Run Duration' +'</td>'
		WHEN Warning = 16 THEN '<td width="100" bgcolor="#FFFF00">' + 'Merge Slow Run Duration' +'</td>'
		WHEN Warning = 32 THEN '<td width="100" bgcolor="#FFFF00">' + 'Marge Fast Run Speed' +'</td>'
		WHEN Warning = 64 THEN '<td width="100" bgcolor="#FFFF00">' + 'Merge Slow Run Speed' +'</td>'
		ELSE '<td width="100" class="c1">' + 'N/A'														
	END +
	CASE
		WHEN publication_type = 0 THEN '<td width="125" class="c2">' + CAST(Best_Latency AS NVARCHAR) +'</td>'
		WHEN publication_type = 1 THEN '<td width="125" class="c2">' + CAST(Best_RunSpeedPerf AS NVARCHAR) +'</td>'
	END +
	CASE
		WHEN publication_type = 0 THEN '<td width="125" class="c1">' + CAST(Worst_Latency AS NVARCHAR) +'</td>'
		WHEN publication_type = 1 THEN '<td width="125" class="c1">' + CAST(Worst_RunSpeedPerf AS NVARCHAR) +'</td>'
	END +
	CASE
		WHEN publication_type = 0 THEN '<td width="125" class="c2">' + CAST(Average_Latency AS NVARCHAR) +'</td>'
		WHEN publication_type = 1 THEN '<td width="125" class="c2">' + CAST(Average_RunSpeedPerf AS NVARCHAR) +'</td>'
	END +
	'<td width="150" class="c1">' + CAST(Last_DistSync AS NVARCHAR) +'</td>' + 
	'</tr>'
FROM #PUBINFO

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Replication Publisher</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">Publisher is not setup on this system</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #REPLSUB)
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Replication Subscriptions</th></tr></table></div><div>
	<table width="1150">   
	<tr> 
	<th width="150">Publisher</th>      
	<th width="150">Publisher DB</th>   
	<th width="150">Publication</th>   
	<th width="450">Distribution Job</th>
	<th width="150">Last Sync</th>
	<th width="100">Immediate Sync</th>
	</tr>'
SELECT
	@HTML = @HTML +   
	'<tr><td width="150" class="c1">' + Publisher +'</td>' +
	'<td width="150" class="c2">' + Publisher_DB +'</td>' +  
	'<td width="150" class="c1">' + Publication +'</td>' +  
	'<td width="450" class="c2">' + Distribution_Agent +'</td>' +  
	'<td width="150" class="c1">' + CAST([time] AS NVARCHAR) +'</td>' +  
	CASE [Immediate_sync]
		WHEN 0 THEN '<td width="100" class="c2">' + 'No'  +'</td>'
		WHEN 1 THEN '<td width="100" class="c2">' + 'Yes'  +'</td>'
		ELSE 'N/A'
	END +
	 '</tr>'
FROM #REPLSUB

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Replication Subscriptions</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">Subscriptions are not setup on this system</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #PERFSTATS)
BEGIN
	SELECT @HTML = @HTML + 
		'&nbsp;<div><table width="1150"> <tr><th class="Perfthheader" width="1150">Connections - Last 24 Hours</th></tr></table></div><div>
		<table width="1150">
			<tr>'
	SELECT @HTML = @HTML + '<th class="Perfth"><img src="foo" style="background-color:white;" height="'+ CAST((COALESCE(UserConnections,0) / 2) AS NVARCHAR) +'" width="10" /></th>'
	FROM #PERFSTATS
	GROUP BY StatDate, UserConnections
	ORDER BY StatDate ASC

	SELECT @HTML = @HTML + '</tr><tr>'
	SELECT @HTML = @HTML + '<td class="Perftd"><p class="Text2">'+ CAST(COALESCE(UserConnections,0) AS NVARCHAR) +'</p></td>'
	FROM #PERFSTATS
	GROUP BY StatDate, UserConnections
	ORDER BY StatDate ASC

	SELECT @HTML = @HTML + '</tr><tr>'
	SELECT @HTML = @HTML + '<td class="Perftd"><div class="Text">'+ 
	CAST(CAST(DATEPART(mm, StatDate)AS NVARCHAR) + '/' + 
	CAST(DATEPART(dd, StatDate)AS NVARCHAR) + '/' + 
	CAST(DATEPART(yyyy, StatDate)AS NVARCHAR)
	 + '  ' + 
	RIGHT('0' + CONVERT(NVARCHAR(2), DATEPART(hh, StatDate)), 2) + ':' +
	RIGHT('0' + CONVERT(NVARCHAR(2), DATEPART(mi, StatDate)), 2)
	 AS NVARCHAR) +'</div></td>'
	FROM #PERFSTATS
	GROUP BY StatDate, UserConnections
	ORDER BY StatDate ASC

	SELECT @HTML = @HTML + '</tr></table></div>&nbsp;'
	SELECT @HTML = @HTML +
		'<div><table width="1150"> <tr><th class="Perfthheader" width="1150">Buffer Hit Cache Ratio - Last 24 Hours</th></tr></table></div><div>
		<table width="1150">
			<tr>'
	SELECT @HTML = @HTML + '<th class="Perfth"><img src="foo" style="background-color:white;" height="'+ CAST((BufferCacheHitRatio/2) AS NVARCHAR) +'" width="10" /></th>'
	FROM #PERFSTATS
	GROUP BY StatDate, BufferCacheHitRatio
	ORDER BY StatDate ASC

	SELECT @HTML = @HTML + '</tr><tr>'
	SELECT @HTML = @HTML + '<td class="Perftd">' + 

	CASE WHEN BufferCacheHitRatio < 98 THEN '<p class="Alert">'+ LEFT(CAST(BufferCacheHitRatio AS NVARCHAR),6) 
		WHEN BufferCacheHitRatio < 99.5 THEN '<p class="Warning">'+ LEFT(CAST(BufferCacheHitRatio AS NVARCHAR),6) 
	ELSE '<p class="Text2">'+ LEFT(CAST(BufferCacheHitRatio AS NVARCHAR),6) 
	END + '</p></td>'
	FROM #PERFSTATS
	GROUP BY StatDate, BufferCacheHitRatio
	ORDER BY StatDate ASC

	SELECT @HTML = @HTML + '</tr><tr>'
	SELECT @HTML = @HTML + '<td class="Perftd"><div class="Text">'+ 
	CAST(CAST(DATEPART(mm, StatDate)AS NVARCHAR) + '/' + 
	CAST(DATEPART(dd, StatDate)AS NVARCHAR) + '/' + 
	CAST(DATEPART(yyyy, StatDate)AS NVARCHAR)
	 + '  ' + 
	RIGHT('0' + CONVERT(NVARCHAR(2), DATEPART(hh, StatDate)), 2) + ':' +
	RIGHT('0' + CONVERT(NVARCHAR(2), DATEPART(mi, StatDate)), 2)
	 AS NVARCHAR) +'</div></td>'
	FROM #PERFSTATS
	GROUP BY StatDate, BufferCacheHitRatio
	ORDER BY StatDate ASC

	SELECT @HTML = @HTML + '</tr></table></div>'
END

IF EXISTS (SELECT * FROM #CPUSTATS)
BEGIN
	SELECT @HTML = @HTML + 
		'&nbsp;<div><table width="1150"> <tr><th class="Perfthheader" width="1150">SQL Server CPU Usage (Percent) - Last 24 Hours</th></tr></table></div><div>
		<table width="1150">
			<tr>'
	SELECT @HTML = @HTML + '<th class="Perfth"><img src="foo" style="background-color:white;" height="'+ CAST((COALESCE(SQLProcessPercent,0) / 2) AS NVARCHAR) +'" width="10" /></th>'
	FROM #CPUSTATS
	GROUP BY DateStamp, SQLProcessPercent
	ORDER BY DateStamp ASC

	SELECT @HTML = @HTML + '</tr><tr>'
	SELECT @HTML = @HTML + '<td class="Perftd"><p class="Text2">'+ CAST(COALESCE(SQLProcessPercent,0) AS NVARCHAR) +'</p></td>'
	FROM #CPUSTATS
	GROUP BY DateStamp, SQLProcessPercent
	ORDER BY DateStamp ASC

	SELECT @HTML = @HTML + '</tr><tr>'
	SELECT @HTML = @HTML + '<td class="Perftd"><div class="Text">'+ 
	CAST(CAST(DATEPART(mm, DateStamp)AS NVARCHAR) + '/' + 
	CAST(DATEPART(dd, DateStamp)AS NVARCHAR) + '/' + 
	CAST(DATEPART(yyyy, DateStamp)AS NVARCHAR)
	 + '  ' + 
	RIGHT('0' + CONVERT(NVARCHAR(2), DATEPART(hh, DateStamp)), 2) + ':' +
	RIGHT('0' + CONVERT(NVARCHAR(2), DATEPART(mi, DateStamp)), 2)
	 AS NVARCHAR) +'</div></td>'
	FROM #CPUSTATS
	GROUP BY DateStamp, SQLProcessPercent
	ORDER BY DateStamp ASC

	SELECT @HTML = @HTML + '</tr></table></div>'
END

IF EXISTS (SELECT * FROM #JOBSTATUS)
BEGIN
SELECT @HTML = @HTML + 
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">SQL Agent Jobs</th></tr></table></div><div>
	<table width="1150"> 
	<tr> 
	<th width="275">Job Name</th>
	<th width="150">Category</th> 
	<th width="75">Enabled</th> 
	<th width="100">Last Outcome</th> 
	<th width="150">Last Date Run</th> 
	<th width="200">Avg Run Time ss(Mi)</th> 
	<th width="200">Execution Time ss(Mi)</th>
	</tr>'
SELECT @HTML = @HTML +   
	'<tr><td width="275" class="c1">' + LEFT(JobName,60) +'</td>' +    
	'<td width="150" class="c2">' + Category +'</td>' +    
	CASE [Enabled]
		WHEN 0 THEN '<td width="75" bgcolor="#FFFF00">False</td>'  
		WHEN 1 THEN '<td width="75" class="c1">True</td>'  
	ELSE '<td width="75" class="c1"><b>Unknown</b></td>'  
	END  +   
 	CASE      
		WHEN LastRunOutcome = 'ERROR' AND RunTimeStatus = 'NormalRunning-History' THEN '<td width="150" bgColor="#FF0000"><b>FAILED</b></td>'
		WHEN LastRunOutcome = 'ERROR' AND RunTimeStatus = 'LongRunning-History' THEN '<td width="150"  bgColor="#FF0000"><b>ERROR - Long Running</b></td>'  
		WHEN LastRunOutcome = 'SUCCESS' AND RunTimeStatus = 'NormalRunning-History' THEN '<td width="150"  bgColor="#00FF00">Success</td>'  
		WHEN LastRunOutcome = 'Success' AND RunTimeStatus = 'LongRunning-History' THEN '<td width="150"  bgColor="#99FF00">Success - Long Running</td>'  
		WHEN LastRunOutcome = 'InProcess' THEN '<td width="150" bgColor="#00FFFF">InProcess</td>'  
		WHEN LastRunOutcome = 'InProcess' AND RunTimeStatus = 'LongRunning-NOW' THEN '<td width="150" bgColor="#00FFFF">InProcess</td>'  
		WHEN LastRunOutcome = 'CANCELLED' THEN '<td width="150" bgColor="#FFFF00"><b>CANCELLED</b></td>'  
		WHEN LastRunOutcome = 'NA' THEN '<td width="150" class="c2">NA</td>'  
	ELSE '<td width="150" class="c2">NA</td>' 
	END + 
	'<td width="150" class="c1">' + COALESCE(CAST(StartTime AS NVARCHAR),'N/A') + '</td>' +
	'<td width="200" class="c2">' + COALESCE(CONVERT(NVARCHAR(50), AvgRuntime),'') + ' (' + COALESCE(CONVERT(NVARCHAR(50), AvgRuntime / 60),'') +  ')' + '</td>' +
	'<td width="200" class="c1">' + COALESCE(CONVERT(NVARCHAR(50), LastRunTime),'') + ' (' + COALESCE(CONVERT(NVARCHAR(50), LastRunTime / 60),'') +  ')' + '</td></tr>'   
FROM #JOBSTATUS
ORDER BY JobName

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #LONGQUERIES)
BEGIN
SELECT @HTML = @HTML +   
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Long Running Queries</th></tr></table></div><div>
	<table width="1150">
	<tr>
	<th width="150">Date Stamp</th> 	
	<th width="150">Database</th>
	<th width="75">Time (ss)</th> 
	<th width="75">SPID</th> 	
	<th width="175">Login</th> 	
	<th width="425">Query Text</th>
	</tr>'
SELECT @HTML = @HTML +   
	'<tr>
	<td width="150" class="c1">' + CAST(DateStamp AS NVARCHAR) +'</td>	
	<td width="150" class="c2">' + [DBName] +'</td>
	<td width="75" class="c1">' + CAST([ElapsedTime(ss)] AS NVARCHAR) +'</td>
	<td width="75" class="c2">' + CAST(Session_id AS NVARCHAR) +'</td>
	<td width="175" class="c1">' + login_name +'</td>	
	<td width="425" class="c2">' + LEFT(sql_text,100) +'</td>			
	</tr>'
FROM #LONGQUERIES
ORDER BY DateStamp

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Long Running Queries</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">There has been no recent recorded long running queries</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #BLOCKING)
BEGIN
SELECT @HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Blocking</th></tr></table></div><div>
	<table width="1150">
	<tr> 
	<th width="150">Date Stamp</th> 
	<th width="150">Database</th> 	
	<th width="60">Time (ss)</th> 
	<th width="60">Victim SPID</th>
	<th width="145">Victim Login</th>
	<th width="190">Victim SQL Text</th> 
	<th width="60">Blocking SPID</th> 	
	<th width="145">Blocking Login</th>
	<th width="190">Blocking SQL Text</th> 
	</tr>'
SELECT @HTML = @HTML +   
	'<tr>
	<td width="150" class="c1">' + CAST(DateStamp AS NVARCHAR) +'</td>
	<td width="130" class="c2">' + [DBName] + '</td>
	<td width="60" class="c1">' + CAST(Blocked_WaitTime_Seconds AS NVARCHAR) +'</td>
	<td width="60" class="c2">' + CAST(Blocked_SPID AS NVARCHAR) +'</td>
	<td width="145" class="c1">' + Blocked_Login +'</td>		
	<td width="200" class="c2">' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LEFT(Blocked_SQL_Text,100),'CREATE',''),'TRIGGER',''),'PROCEDURE',''),'FUNCTION',''),'PROC','') +'</td>
	<td width="60" class="c1">' + CAST(Blocking_SPID AS NVARCHAR) +'</td>
	<td width="145" class="c2">' + Offending_Login +'</td>
	<td width="200" class="c1">' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LEFT(Offending_SQL_Text,100),'CREATE',''),'TRIGGER',''),'PROCEDURE',''),'FUNCTION',''),'PROC','') +'</td>	
	</tr>'
FROM #BLOCKING
ORDER BY DateStamp

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Blocking</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">There has been no recent recorded blocking</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #DEADLOCKINFO)
BEGIN
SELECT @HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Deadlocks - Prior Day</th></tr></table></div><div>
	<table width="1150">
	<tr> 
	<th width="150">Date Stamp</th> 
	<th width="150">Database</th> 	
	<th width="75">Victim Hostname</th> 
	<th width="75">Victim Login</th>
	<th width="75">Victim SPID</th>
	<th width="200">Victim Objects</th> 	
	<th width="75">Locking Hostname</th>
	<th width="75">Locking Login</th> 
	<th width="75">Locking SPID</th> 
	<th width="200">Locking Objects</th>
	</tr>'
SELECT @HTML = @HTML +   
	'<tr>
	<td width="150" class="c1">' + CAST(DeadlockDate AS NVARCHAR) +'</td>
	<td width="150" class="c2">' + [DBName] + '</td>' +
	CASE 
		WHEN VictimLogin IS NOT NULL THEN '<td width="75" class="c1">' + COALESCE(VictimHostname,'NA') +'</td>'
	ELSE '<td width="75" class="c1">NA</td>' 
	END +
	'<td width="75" class="c2">' + COALESCE(VictimLogin,'NA') +'</td>' +
	CASE 
		WHEN VictimLogin IS NOT NULL THEN '<td width="75" class="c1">' + COALESCE(VictimSPID,'NA') +'</td>'
	ELSE '<td width="75" class="c1">NA</td>' 
	END +	
	'<td width="200" class="c2">' + COALESCE(VictimSQL,'NA') +'</td>
	<td width="75" class="c1">' + COALESCE(LockingHostname,'NA') +'</td>
	<td width="75" class="c2">' + COALESCE(LockingLogin,'NA') +'</td>
	<td width="75" class="c1">' + COALESCE(LockingSPID,'NA') +'</td>		
	<td width="200" class="c2">' + COALESCE(LockingSQL,'NA') +'</td>
	</tr>'
FROM #DEADLOCKINFO 
WHERE (VictimLogin IS NOT NULL OR LockingLogin IS NOT NULL)
ORDER BY DeadlockDate ASC

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Deadlocks - Previous Day</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">There has been no recent recorded Deadlocks OR TraceFlag 1222 is not Active</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #SCHEMACHANGES)
BEGIN
SELECT @HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Schema Changes</th></tr></table></div><div>
	<table width="1150">
	  <tr>
	  	<th width="150">Create Date</th>
	  	<th width="150">Database</th>
		<th width="150">SQL Event</th>	  		
		<th width="350">Object Name</th>
		<th width="175">Login Name</th>
		<th width="175">Computer Name</th>
	 </tr>'
SELECT @HTML = @HTML +   
	'<tr><td width="150" class="c1">' + CAST(CreateDate AS NVARCHAR) +'</td>' +  
	'<td width="150" class="c2">' + COALESCE([DBName],'N/A') +'</td>' +
	'<td width="150" class="c1">' + SQLEvent +'</td>' +
	'<td width="350" class="c2">' + COALESCE(ObjectName,'N/A') +'</td>' +  
	'<td width="175" class="c1">' + COALESCE(LoginName,'N/A') +'</td>' +  
	'<td width="175" class="c2">' + COALESCE(ComputerName,'N/A') +'</td></tr>'
FROM #SCHEMACHANGES
ORDER BY [DBName], CreateDate

SELECT 
	@HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Schema Changes</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">There has been no recent recorded schema changes</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #ERRORLOG)
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Error Log - Last 24 Hours (Does not include Backup or Deadlock info)</th></tr></table></div><div>
	<table width="1150">
	<tr>
	<th width="150">Log Date</th>
	<th width="150">Process Info</th>
	<th width="850">Message</th>
	</tr>'
SELECT
	@HTML = @HTML +
	'<tr>
	<td width="150" class="c1">' + COALESCE(CAST(LogDate AS NVARCHAR),'N/A') +'</td>' +
	'<td width="150" class="c2">' + COALESCE(ProcessInfo,'N/A') +'</td>' +
	'<td width="850" class="c1">' + COALESCE([text],'N/A') +'</td>' +
	 '</tr>'
FROM #ERRORLOG
ORDER BY LogDate DESC

SELECT @HTML = @HTML + '</table></div>'
END

IF EXISTS (SELECT * FROM #BACKUPS)
BEGIN
SELECT
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Backup Stats - Last 24 Hours</th></tr></table></div><div>
	<table width="1150">
	<tr>
	<th width="150">Database</th>
	<th width="90">Type</th>
	<th width="300">File Name</th>
	<th width="160">Backup Set Name</th>		
	<th width="150">Start Date</th>
	<th width="150">End Date</th>
	<th width="75">Size (GB)</th>
	<th width="75">Age (hh)</th>
	</tr>'
SELECT
	@HTML = @HTML +   
	'<tr> 
	<td width="150" class="c1">' + COALESCE([DBName],'N/A') +'</td>' +
	'<td width="90" class="c2">' + COALESCE([Type],'N/A') +'</td>' +
	'<td width="300" class="c1">' + COALESCE([Filename],'N/A') +'</td>' +
	'<td width="160" class="c2">' + COALESCE(backup_set_name,'N/A') +'</td>' +	
	'<td width="150" class="c1">' + COALESCE(CAST(backup_start_date AS NVARCHAR),'N/A') +'</td>' +  
	'<td width="150" class="c2">' + COALESCE(CAST(backup_finish_date AS NVARCHAR),'N/A') +'</td>' +  
	'<td width="75" class="c1">' + COALESCE(CAST(backup_size AS NVARCHAR),'N/A') +'</td>' +  
	'<td width="75" class="c2">' + COALESCE(CAST(backup_age AS NVARCHAR),'N/A') +'</td>' +  	
	 '</tr>'
FROM #BACKUPS
ORDER BY backup_start_date DESC

SELECT @HTML = @HTML + '</table></div>'
END ELSE
BEGIN
SELECT 
	@HTML = @HTML +
	'&nbsp;<div><table width="1150"> <tr><th class="header" width="1150">Backup Stats - Last 24 Hours</th></tr></table></div><div>
	<table width="1150">   
		<tr> 
			<th width="1150">No backups have been created on this server in the last 24 hours</th>
		</tr>'

SELECT @HTML = @HTML + '</table></div>'
END

SELECT @HTML = @HTML + '&nbsp;<div><table width="1150"><tr><td class="master">Generated on ' + CAST(GETDATE() AS NVARCHAR) + '</td></tr></table></div>'

SELECT @HTML = @HTML + '</body></html>'

/* STEP 3: SEND REPORT */

IF @EmailFlag = 1
BEGIN
EXEC msdb..sp_send_dbmail
	@recipients=@Recepients,
	@copy_recipients=@CC,  
	@subject = @ReportTitle,    
	@body = @HTML,    
	@body_format = 'HTML'
END

/* STEP 4: PRESERVE DATA */

IF @InsertFlag = 1
BEGIN
IF EXISTS (SELECT name FROM master..sysdatabases WHERE name = 'dba')
BEGIN
	INSERT INTO [dba].dbo.HealthReport (GeneratedHTML)
	SELECT @HTML
END
END

DROP TABLE #SYSINFO
DROP TABLE #PROCESSOR
DROP TABLE #DRIVES
DROP TABLE #CLUSTER
DROP TABLE #TRACESTATUS
DROP TABLE #DATABASES
DROP TABLE #FILESTATS
DROP TABLE #VLFINFO
DROP TABLE #JOBSTATUS
DROP TABLE #LONGQUERIES
DROP TABLE #BLOCKING
DROP TABLE #SCHEMACHANGES
DROP TABLE #REPLINFO
DROP TABLE #PUBINFO
DROP TABLE #REPLSUB
DROP TABLE #LOGSHIP
DROP TABLE #MIRRORING
DROP TABLE #ERRORLOG
DROP TABLE #BACKUPS
DROP TABLE #PERFSTATS
DROP TABLE #CPUSTATS
DROP TABLE #DEADLOCKINFO
DROP TABLE #TEMPDATES

END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'gen_GetHealthReportHTML' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.gen_GetHealthReportHTML AS SELECT 1')
END
GO

ALTER PROC dbo.gen_GetHealthReportHTML (@DateStamp NVARCHAR(20))
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**  08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN

DECLARE @HealthReportID INT

SET @HealthReportID = (SELECT MIN(HealthReportID) FROM [dba].dbo.HealthReport(nolock) WHERE DateStamp >= @DateStamp)

SELECT
hr.GeneratedHTML
FROM [dba].dbo.HealthReport(nolock) hr
WHERE hr.HealthReportID = @HealthReportID

END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'gen_GetHealthReportToEmail' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.gen_GetHealthReportToEmail AS SELECT 1')
END
GO

ALTER PROC dbo.gen_GetHealthReportToEmail (@DateStamp NVARCHAR(20), @EmailAddress NVARCHAR(100))
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**  08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN

IF EXISTS (SELECT MIN(HealthReportID) FROM [dba].dbo.HealthReport(nolock) WHERE DateStamp >= @DateStamp)
BEGIN

DECLARE @HealthReportID INT,
		@SubjectLine NVARCHAR(255), 
		@FileDateStamp NVARCHAR(20), 
		@HTML NVARCHAR(MAX)
		
SELECT @HealthReportID = MIN(HealthReportID) FROM [dba].dbo.HealthReport(nolock) WHERE DateStamp >= @DateStamp	
SELECT @FileDateStamp = (DATEPART(YEAR,@DateStamp) * 10000 + DATEPART(MONTH,@DateStamp) * 100 + DATEPART(DAY,@DateStamp))
SELECT @SubjectLine = 'Database Health Report - ' + @DateStamp
SELECT @HTML = GeneratedHTML FROM [dba].dbo.HealthReport WHERE HealthReportID = @HealthReportID


EXEC msdb.dbo.sp_send_dbmail
@recipients= @EmailAddress,
@subject = @SubjectLine,
@body = @HTML,
@body_format = 'HTML'

END
END
GO

USE [dba]
GO

IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'gen_GetHealthReportToFile' 
		  AND ROUTINE_SCHEMA = 'dbo'
		  AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	EXEC ('CREATE PROC dbo.gen_GetHealthReportToFile AS SELECT 1')
END
GO

ALTER PROC dbo.gen_GetHealthReportToFile (@DateStamp NVARCHAR(20), @Path NVARCHAR(100))
AS

/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**  08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
***************************************************************************************************************/

BEGIN

IF EXISTS (SELECT MIN(HealthReportID) FROM [dba].dbo.HealthReport(nolock) WHERE DateStamp >= @DateStamp)
BEGIN -- <WriteHealthReport>

DECLARE @FileDateStamp NVARCHAR(20), @SQL NVARCHAR(250)
SELECT @FileDateStamp = (DATEPART(year,@DateStamp) * 10000 + DATEPART(month,@DateStamp) * 100 + DATEPART(day,@DateStamp))

SET @SQL = 'bcp "EXEC [dba].dbo.gen_GetHealthReportHTML ' + '''' + @DateStamp + '''' +'" queryout "' + @Path + 'HealthReport' + @FileDateStamp + '.html" /c /Usa /Pqwmrp'

-- Determine if xp_cmdshell is already enabled
DECLARE @xpCmdShellEnabledAtStart int = 0

SELECT @xpCmdShellEnabledAtStart = CONVERT(INT, ISNULL(value_in_use, value))
FROM  sys.configurations
WHERE name = 'xp_cmdshell' ;

If @xpCmdShellEnabledAtStart = 0
BEGIN
	EXEC sp_configure 'show advanced options', 1
	RECONFIGURE
	EXEC sp_configure 'xp_cmdshell', 1
	RECONFIGURE

	EXEC master..xp_cmdshell @SQL

	EXEC sp_configure 'show advanced options', 1
	RECONFIGURE
	EXEC sp_configure 'xp_cmdshell', 0
	RECONFIGURE
END
Else
	EXEC master..xp_cmdshell @SQL

END -- </WriteHealthReport>
END
GO
/*======================================================================================================================================================
========================================================================================================================================================
========================================================================================================================================================
========================================================================================================================================================
=============================================================== JOBS ===================================================================================
========================================================================================================================================================
========================================================================================================================================================
========================================================================================================================================================
======================================================================================================================================================*/
	/* CATEGORY */
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Monitoring' AND category_class=1)
BEGIN
EXEC msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Monitoring'
END

	/* JOBS */
USE [msdb]
GO

IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'dba_BlockingAlert')
BEGIN
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'dba_BlockingAlert', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Monitoring',
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dba].dbo.usp_CheckBlocking', 
		@database_name=N'dba', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Check for blocking', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=127, 
		@freq_subday_type=2, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20110308, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=190000
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
END
GO

IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'dba_HealthReport')
BEGIN
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'dba_HealthReport', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Monitoring',
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dba].dbo.rpt_HealthReport @Recepients = NULL, @CC = NULL, @InsertFlag = 1', 
		@database_name=N'dba', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110204, 
		@active_end_date=99991231, 
		@active_start_time=60500, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
END
GO

IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'dba_LongRunningJobsAlert')
BEGIN
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'dba_LongRunningJobsAlert', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Monitoring',
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dba].dbo.usp_LongRunningJobs', 
		@database_name=N'dba', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110531, 
		@active_end_date=99991231, 
		@active_start_time=500, 
		@active_end_time=459
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
END
GO

IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'dba_CheckFiles')
BEGIN
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'dba_CheckFiles', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Monitoring',
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dba].dbo.usp_CheckFiles', 
		@database_name=N'dba', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110623, 
		@active_end_date=99991231, 
		@active_start_time=3000, 
		@active_end_time=2959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
END
GO

IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'dba_LongRunningQueriesAlert')
BEGIN
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'dba_LongRunningQueriesAlert', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Monitoring',
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dba].dbo.usp_LongRunningQueries', 
		@database_name=N'dba', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=126, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20110616, 
		@active_end_date=99991231, 
		@active_start_time=200, 
		@active_end_time=159
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sunday schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20110718, 
		@active_end_date=99991231, 
		@active_start_time=190200, 
		@active_end_time=170159
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
END
GO

IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'dba_PerfStats')
BEGIN
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'dba_PerfStats', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Monitoring',
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run exec', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dba].dbo.usp_PerfStats 1', 
		@database_name=N'dba', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'perfstats schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110809, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
END
GO

IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'dba_MemoryUsageStats')
BEGIN
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'dba_MemoryUsageStats', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Monitoring', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dba].dbo.usp_MemoryUsageStats 1', 
		@database_name=N'dba', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20111101, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
END
GO

IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'dba_CPUAlert')
BEGIN
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'dba_CPUAlert', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Monitoring', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run proc]    Script Date: 02/29/2012 11:32:46 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dba].dbo.usp_CPUProcessAlert', 
		@database_name=N'dba', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120229, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
END
GO

/*============================================================================================================================================================
==============================================================================================================================================================
==============================================================================================================================================================
==============================================================================================================================================================
==============================================================================================================================================================
=========================================================Data Dictionary Execution============================================================================
==============================================================================================================================================================
==============================================================================================================================================================
==============================================================================================================================================================
==============================================================================================================================================================
============================================================================================================================================================*/
USE [dba]
GO

----RUN THIS TO POPULATE DATA DICTIONARY PROCESS TABLES
EXEC [dba].dbo.dd_PopulateDataDictionary
GO
----RUN ALL THESE UPDATES TO POPULATE THE TABLES AND FIELDS
--TABLES

UPDATE dbo.DataDictionary_Tables SET TableDescription = 'List of fields' WHERE TableName = 'DataDictionary_Fields'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'List of tables' WHERE TableName = 'DataDictionary_Tables'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'Contains config data for SQL Jobs such as email, query parameters' WHERE TableName = 'AlertSettings'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'Contains history on blocking sessions and the victims' WHERE TableName = 'BlockingHistory'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'Storage for historical generated HealthReports' WHERE TableName = 'HealthReport'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'Contains statistical inforamtion on SQL Jobs' WHERE TableName = 'JobStatsHistory'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'Contains statistics on ' WHERE TableName = 'PerfStatsHistory'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'Storage for long running queries' WHERE TableName = 'QueryHistory'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'History table on CPU statistics' WHERE TableName = 'CPUStatsHistory'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'Settings to turn on/off schema tracking, reindexing and alerts on specific databases' WHERE TableName = 'DatabaseSettings'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'History table on DB file statistics ' WHERE TableName = 'FileStatsHistory'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'History table on memory usage statistics' WHERE TableName = 'MemoryUsageHistory'
UPDATE dbo.DataDictionary_Tables SET TableDescription = 'Database trigger to audit all of the DDL changes made to the database.' WHERE TableName = 'SchemaChangeLog'

--FIELDS

UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Field Description' WHERE TableName = 'DataDictionary_Fields' AND FieldName = 'FieldDescription'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Field Name' WHERE TableName = 'DataDictionary_Fields' AND FieldName = 'FieldName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Schema Name' WHERE TableName = 'DataDictionary_Fields' AND FieldName = 'SchemaName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Table Name' WHERE TableName = 'DataDictionary_Fields' AND FieldName = 'TableName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Schema Name' WHERE TableName = 'DataDictionary_Tables' AND FieldName = 'SchemaName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Table Description' WHERE TableName = 'DataDictionary_Tables' AND FieldName = 'TableDescription'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Table Name' WHERE TableName = 'DataDictionary_Tables' AND FieldName = 'TableName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Cell numbers for texting alerts' WHERE TableName = 'AlertSettings' AND FieldName = 'CellList'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Email addresses for emailing alerts' WHERE TableName = 'AlertSettings' AND FieldName = 'EmailList'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Secondary email address for emailing alerts' WHERE TableName = 'AlertSettings' AND FieldName = 'EmailList2'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Stores a value sometimes used by SQL Jobs' WHERE TableName = 'AlertSettings' AND FieldName = 'JobValue'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The description of what is stored in the JobValue column' WHERE TableName = 'AlertSettings' AND FieldName = 'JobValueDesc'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The name of the alert, corresponding to a SQL Job' WHERE TableName = 'AlertSettings' AND FieldName = 'Name'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Stores the values used by the query run by the SQL Job or stored proc' WHERE TableName = 'AlertSettings' AND FieldName = 'QueryValue'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The description of what is stored in the QueryValue column' WHERE TableName = 'AlertSettings' AND FieldName = 'QueryValueDesc'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The hostname of the victim session' WHERE TableName = 'BlockingHistory' AND FieldName = 'BLOCKED_HOSTNAME'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The Last WAITTYPE of the victim session' WHERE TableName = 'BlockingHistory' AND FieldName = 'BLOCKED_LASTWAITTYPE'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The Login name of the victim session' WHERE TableName = 'BlockingHistory' AND FieldName = 'BLOCKED_LOGIN'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The program used by the victim session' WHERE TableName = 'BlockingHistory' AND FieldName = 'BLOCKED_PROGRAM'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The SPID of the victim session' WHERE TableName = 'BlockingHistory' AND FieldName = 'BLOCKED_SPID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The SQL text run by the victim session' WHERE TableName = 'BlockingHistory' AND FieldName = 'BLOCKED_SQL_TEXT'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The Status of the victim session' WHERE TableName = 'BlockingHistory' AND FieldName = 'BLOCKED_STATUS'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The time in seconds the victim session was being blocked' WHERE TableName = 'BlockingHistory' AND FieldName = 'BLOCKED_WAITTIME_SECONDS'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The SPID of the offending session' WHERE TableName = 'BlockingHistory' AND FieldName = 'BLOCKING_SPID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The PK on the table' WHERE TableName = 'BlockingHistory' AND FieldName = 'BlockingHistoryID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The datestamp on when the data was collected' WHERE TableName = 'BlockingHistory' AND FieldName = 'DateStamp'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The hostname of the offending session' WHERE TableName = 'BlockingHistory' AND FieldName = 'OFFENDING_HOSTNAME'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The Last WAITTYPE of the offending session' WHERE TableName = 'BlockingHistory' AND FieldName = 'OFFENDING_LASTWAITTYPE'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The Login ' WHERE TableName = 'BlockingHistory' AND FieldName = 'OFFENDING_LOGIN'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The NTUser of the offending session' WHERE TableName = 'BlockingHistory' AND FieldName = 'OFFENDING_NTUSER'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The program used by the offending session' WHERE TableName = 'BlockingHistory' AND FieldName = 'OFFENDING_PROGRAM'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'DUPLICATE - The SPID of the offending session' WHERE TableName = 'BlockingHistory' AND FieldName = 'OFFENDING_SPID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The SQL Text run by the offending session' WHERE TableName = 'BlockingHistory' AND FieldName = 'OFFENDING_SQL_TEXT'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The Status of the offending session' WHERE TableName = 'BlockingHistory' AND FieldName = 'OFFENDING_STATUS'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The WAITTYPE of the offending session' WHERE TableName = 'BlockingHistory' AND FieldName = 'OFFENDING_WAITTYPE'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The datestamp the HealthReport was generated' WHERE TableName = 'HealthReport' AND FieldName = 'DateStamp'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The HTML blob that represents the HealthReport' WHERE TableName = 'HealthReport' AND FieldName = 'GeneratedHTML'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The PK for the HealthReport' WHERE TableName = 'HealthReport' AND FieldName = 'HealthReportID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The average runtime of the SQL Job' WHERE TableName = 'JobStatsHistory' AND FieldName = 'AvgRunTime'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Stores the status of the job, enabled or disabled' WHERE TableName = 'JobStatsHistory' AND FieldName = 'Enabled'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The name of the SQL Job' WHERE TableName = 'JobStatsHistory' AND FieldName = 'JobName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The datestamp that the job stats were gathered' WHERE TableName = 'JobStatsHistory' AND FieldName = 'JobStatsDateStamp'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The PK on the table' WHERE TableName = 'JobStatsHistory' AND FieldName = 'JobStatsHistoryId'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The grouping ID for all records gathered for that time stamp' WHERE TableName = 'JobStatsHistory' AND FieldName = 'JobStatsID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The outcome of the SQL Job, whether is succeeded or failed' WHERE TableName = 'JobStatsHistory' AND FieldName = 'LastRunOutcome'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The last time the SQL Job was run' WHERE TableName = 'JobStatsHistory' AND FieldName = 'LastRunTime'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Whether the job is currently running or not (at the time the information was gathered)' WHERE TableName = 'JobStatsHistory' AND FieldName = 'RunTimeStatus'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The time the SQL Job started' WHERE TableName = 'JobStatsHistory' AND FieldName = 'StartTime'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The time the SQL Job stopped' WHERE TableName = 'JobStatsHistory' AND FieldName = 'StopTime'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of batches SQL Server is receiving per second' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'BatchRequestsPerSecond'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'How often SQL Server is able data pages in its buffer cache' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'BufferCacheHitRatio'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of checkpoint pages per second' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'CheckpointPagesPerSecond'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of compilations per second' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'CompilationsPerSecond'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of lock waits per second' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'LockWaitsPerSecond'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The life expectancy of hte page' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'PageLifeExpectency'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of page splits per second' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'PageSplitsPerSecond'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The PK on the table' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'PerfStatsHistoryID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of processes blocked' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'ProcessesBlocked'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of recompilations per second' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'ReCompilationsPerSecond'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The timestamp the data was gathered' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'StatDate'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of users connected' WHERE TableName = 'PerfStatsHistory' AND FieldName = 'UserConnections'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The timestamp the data was collected' WHERE TableName = 'QueryHistory' AND FieldName = 'collection_time'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The amount of CPU cycles the query has performed' WHERE TableName = 'QueryHistory' AND FieldName = 'CPU'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The name of the database' WHERE TableName = 'QueryHistory' AND FieldName = 'database_name'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The host name the query originated from' WHERE TableName = 'QueryHistory' AND FieldName = 'host_name'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The login name that ran the query' WHERE TableName = 'QueryHistory' AND FieldName = 'login_name'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The timestamp of when the user logged in' WHERE TableName = 'QueryHistory' AND FieldName = 'login_time'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of physical reads the query performed' WHERE TableName = 'QueryHistory' AND FieldName = 'physical_reads'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The name of the program that initiated the query' WHERE TableName = 'QueryHistory' AND FieldName = 'program_name'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The PK on the table' WHERE TableName = 'QueryHistory' AND FieldName = 'QueryHistoryID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of reads the query performed' WHERE TableName = 'QueryHistory' AND FieldName = 'reads'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The SPID of the query' WHERE TableName = 'QueryHistory' AND FieldName = 'session_id'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The SQL Text of the query' WHERE TableName = 'QueryHistory' AND FieldName = 'sql_text'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The timestamp the query started' WHERE TableName = 'QueryHistory' AND FieldName = 'start_time'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The number of writes the query performed' WHERE TableName = 'QueryHistory' AND FieldName = 'writes'


UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Stores the values used by the query run by the SQL Job or stored proc' WHERE TableName = 'AlertSettings' AND FieldName = 'QueryValue2'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The description of what is stored in the QueryValue column' WHERE TableName = 'AlertSettings' AND FieldName = 'QueryValue2Desc'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The Database where the blocking occured' WHERE TableName = 'BlockingHistory' AND FieldName = 'DBName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Primary Key' WHERE TableName = 'CPUStatsHistory' AND FieldName = 'CPUStatsHistoryID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Datestamp when record was inserted' WHERE TableName = 'CPUStatsHistory' AND FieldName = 'DateStamp'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Percentage all other system processes' WHERE TableName = 'CPUStatsHistory' AND FieldName = 'OtherProcessPerecnt'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Percentage of SQL Server process' WHERE TableName = 'CPUStatsHistory' AND FieldName = 'SQLProcessPercent'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Percentage of system idle process' WHERE TableName = 'CPUStatsHistory' AND FieldName = 'SystemIdleProcessPercent'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The name of the Database' WHERE TableName = 'DatabaseSettings' AND FieldName = 'DBName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Flag to turn on/off Log File Alerts' WHERE TableName = 'DatabaseSettings' AND FieldName = 'LogFileAlerts'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Flag to turn on/off Long running query alerts' WHERE TableName = 'DatabaseSettings' AND FieldName = 'LongQueryAlerts'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Flag to turn on/off reindexing, requires reindex wrapper proc' WHERE TableName = 'DatabaseSettings' AND FieldName = 'Reindex'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Flag to turn on/off Schema tracking' WHERE TableName = 'DatabaseSettings' AND FieldName = 'SchemaTracking'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Database name' WHERE TableName = 'FileStatsHistory' AND FieldName = 'DBName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Drive Letter the file is located' WHERE TableName = 'FileStatsHistory' AND FieldName = 'DriveLetter'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Growth setting for the file' WHERE TableName = 'FileStatsHistory' AND FieldName = 'FileGrowth'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'How much space is available' WHERE TableName = 'FileStatsHistory' AND FieldName = 'FileMBEmpty'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Size of the file in MB' WHERE TableName = 'FileStatsHistory' AND FieldName = 'FileMBSize'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Total space allocated for the file' WHERE TableName = 'FileStatsHistory' AND FieldName = 'FileMBUsed'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Filename' WHERE TableName = 'FileStatsHistory' AND FieldName = 'FileName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Percentage of file that is not being used' WHERE TableName = 'FileStatsHistory' AND FieldName = 'FilePercentEmpty'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Datestamp when record was inserted' WHERE TableName = 'FileStatsHistory' AND FieldName = 'FileStatsDateStamp'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Primary Key' WHERE TableName = 'FileStatsHistory' AND FieldName = 'FileStatsHistoryID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Grouping of records' WHERE TableName = 'FileStatsHistory' AND FieldName = 'FileStatsID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The category of the job' WHERE TableName = 'JobStatsHistory' AND FieldName = 'Category'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferCacheHitRatio' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferCacheHitRatio'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferPageLifeExpectancy' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferPageLifeExpectancy'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferPoolCommitMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferPoolCommitMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferPoolCommitTgtMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferPoolCommitTgtMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferPoolDataPagesMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferPoolDataPagesMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferPoolFreePagesMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferPoolFreePagesMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferPoolPlanCachePagesMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferPoolPlanCachePagesMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferPoolReservedPagesMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferPoolReservedPagesMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferPoolStolenPagesMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferPoolStolenPagesMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'BufferPoolTotalPagesMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'BufferPoolTotalPagesMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'CursorUsageMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'CursorUsageMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Datestamp when record was inserted' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'DateStamp'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'DBMemoryRequiredMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'DBMemoryRequiredMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'DBUsageMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'DBUsageMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'DynamicMemConnectionsMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'DynamicMemConnectionsMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'DynamicMemHashSortIndexMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'DynamicMemHashSortIndexMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'DynamicMemLocksMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'DynamicMemLocksMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'DynamicMemQueryOptimizeMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'DynamicMemQueryOptimizeMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'DynamicMemSQLCacheMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'DynamicMemSQLCacheMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Primary Key' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'MemoryUsageHistoryID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'SystemPhysicalMemoryMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'SystemPhysicalMemoryMB'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'SystemVirtualMemoryMB' WHERE TableName = 'MemoryUsageHistory' AND FieldName = 'SystemVirtualMemoryMB'

UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Name of computer that made the DDL change' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'ComputerName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The date and time the DDL change occurred.' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'CreateDate'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Name of the database' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'DBName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Login of who made the DDL change' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'LoginName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Primary Key' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'SchemaChangeLogID'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The name of the object' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'ObjectName'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The sql text that was run' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'SQLCmd'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'Specifies what type of change, IE ALTER_PROCEDURE, CREATE_FUNCTION, etc' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'SQLEvent'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The schema to which the changed object belongs.' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'Schema'
UPDATE dbo.DataDictionary_Fields SET FieldDescription = 'The raw XML data generated by database trigger.' WHERE TableName = 'SchemaChangeLog' AND FieldName = 'XmlEvent'


----RUN THIS AFTER YOU RUN ALL THE UPDATES BELOW
EXEC [dba].dbo.dd_ApplyDataDictionary
GO
