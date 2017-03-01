/*
 * Originally described at https://www.brentozar.com/sql/locking-and-blocking-in-sql-server/
 * 
 * Utilize the Blocked Process Report Viewer, described at :
 * http://michaeljswart.com/2011/04/a-new-way-to-examine-blocked-process-reports/

 * Download sp_blocked_process_report_viewer from:
 * http://sqlblockedprocesses.codeplex.com/
 *
 */

--Make sure you don't have any pending changes
SELECT *
FROM sys.configurations
WHERE value <> value_in_use;
GO
exec sp_configure 'show advanced options', 1;
GO
RECONFIGURE
GO

--------------------------------------------------------------------------------
-- Change the blocked process threshold to 5 seconds
-- Any blocking that lasts more than 5 seconds will be logged in the trace file
--------------------------------------------------------------------------------
--
exec sp_configure 'blocked process threshold (s)', 5;
GO
RECONFIGURE
GO


--------------------------------------------------------------------------------
-- Define a trace to watch for blocked processes
--------------------------------------------------------------------------------
--
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
declare @DateTime datetime

-- Define the max runtime
set @DateTime = DATEADD(minute, 60, getdate());  /* Run for 60 minutes */

-- Define the maximum file size (in MB)
set @maxfilesize = 5

-- Define the trace file name
-- The .trc extension will be appended to the filename automatically. 
-- Supports local paths or UNC path to a remove share
exec @rc = sp_trace_create @TraceID output, 0, N'E:\SQLServerTraces\BlockedProcessReport_2017-03-01', @maxfilesize, @Datetime
if (@rc != 0) 
	goto error

-- Client side File and Table cannot be scripted
-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 137, 1, @on
exec sp_trace_setevent @TraceID, 137, 12, @on

-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- Display trace id for future references
select TraceID=@TraceID
goto finish

Error:
select ErrorCode=@rc

Finish:
Go

-- Confirm that the trace is running
-- Should have status = 1
SELECT * from sys.traces;
GO

-- If necessary, stop the trace using this (with the correct @traceid)
-- EXEC sp_trace_setstatus @traceid =2, @status = 2;
GO


--------------------------------------------------------------------------------
-- View the trace as a report
-- Get the stored procedure from http://michaeljswart.com/2011/04/a-new-way-to-examine-blocked-process-reports/
--------------------------------------------------------------------------------
--
exec dbo.sp_blocked_process_report_viewer
  @Trace='S:\Traces\BlockedProcessReportDemo.trc';

GO


--------------------------------------------------------------------------------
-- Cleanup when done
--------------------------------------------------------------------------------
--
-- Make sure your trace is gone
SELECT * from sys.traces;
GO

-- Restore the blocked process threshold to 0 (disabled)
exec sp_configure 'blocked process threshold (s)', 0;
GO
RECONFIGURE
GO
exec sp_configure 'blocked process threshold (s)';

