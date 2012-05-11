/****** Object:  StoredProcedure [dbo].[CleanupOperatingLogs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.CleanupOperatingLogs
/****************************************************
** 
**	Desc:	Deletes Info entries from T_Log_Entries if they are
**			more than @InfoHoldoffWeeks weeks old
**
**			Move old log entries and event entries to DMSHistoricLog1
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	10/04/2011 mem - Initial version
**    
*****************************************************/
(
	@LogRetentionIntervalHours int = 120,
	@EventLogRetentionIntervalDays int = 365
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @message varchar(256)
	Set @message = ''
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Begin Try
		
		---------------------------------------------------
		-- Validate the inputs
		---------------------------------------------------
		
		If IsNull(@LogRetentionIntervalHours, 0) < 24
			Set @LogRetentionIntervalHours = 24

		If IsNull(@EventLogRetentionIntervalDays, 0) < 32
			Set @EventLogRetentionIntervalDays = 32

		----------------------------------------------------
		-- Move old log entries from T_Log_Entries to DMSHistoricLog1
		----------------------------------------------------
		--
		Set @CurrentLocation = 'Call MoveHistoricLogEntries'
		
		exec @myError = MoveHistoricLogEntries @LogRetentionIntervalHours

		----------------------------------------------------
		-- Move old log entries from T_Analysis_Log to DMSHistoricLog1
		----------------------------------------------------
		--
		Set @CurrentLocation = 'Call MoveAnalysisLogEntries'
		
		exec @myError = MoveAnalysisLogEntries @LogRetentionIntervalHours
		
		----------------------------------------------------
		-- Move old events from T_Event_Log to DMSHistoricLog1
		----------------------------------------------------
		--
		Set @CurrentLocation = 'Call MoveEventLogEntries'
		
		exec @myError = MoveEventLogEntries @EventLogRetentionIntervalDays
		
	End Try
	Begin Catch
		-- Error caught; log the error
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'CleanupOperatingLogs')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch
	
Done:
	
	return @myError


GO
