/****** Object:  StoredProcedure [dbo].[CleanupOperatingLogs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.CleanupOperatingLogs
/****************************************************
** 
**	Desc:	Move old log entries and event entries to DMSHistoricLogPipeline
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	10/04/2011 mem - Initial version
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@InfoHoldoffWeeks int = 4,
	@LogRetentionIntervalDays int = 365	
)
As
	Set XACT_ABORT, nocount on
	
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
		
		If IsNull(@InfoHoldoffWeeks, 0) < 1
			Set @InfoHoldoffWeeks = 1

		If IsNull(@LogRetentionIntervalDays, 0) < 14
			Set @LogRetentionIntervalDays = 14

		----------------------------------------------------
		-- Delete Info and Warn entries posted more than @InfoHoldoffWeeks weeks ago
		----------------------------------------------------
		--
		Set @CurrentLocation = 'Delete non-noteworthy log entries'
		
		DELETE FROM T_Log_Entries
		WHERE (posting_time < DATEADD(week, -@InfoHoldoffWeeks, GETDATE())) AND 
		      (message LIKE 'Resuming [0-9]%job%' OR
		       message LIKE 'Deleted job % from T_Jobs')
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myError <> 0
		Begin
			Set @message = 'Error deleting old Info messages from T_Log_Entries'
			Exec PostLogEntry 'Error', @message, 'CleanupOperatingLogs'
		End

		----------------------------------------------------
		-- Move old log entries and event entries to DMSHistoricLogPipeline
		----------------------------------------------------
		--
		Set @CurrentLocation = 'Call MoveEntriesToHistory'
		
		exec @myError = MoveEntriesToHistory @LogRetentionIntervalDays
		
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
