/****** Object:  StoredProcedure [dbo].[DoAnalysisJobOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoAnalysisJobOperation
/****************************************************
**
**	Desc: 
**		Perform analysis job operation defined by 'mode'
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	05/02/2002
**			05/05/2005 grk - removed default mode value
**			02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**			08/19/2010 grk - try-catch for error handling
**			11/18/2010 mem - Now returning 0 after successful call to DeleteNewAnalysisJob
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@jobNum varchar(32),
	@mode varchar(12),  -- 'delete, reset'
    @message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	declare @jobID int
	declare @state int
	
	declare @result int

	BEGIN TRY 

	---------------------------------------------------
	-- Delete job if it is in "new" or "failed" state
	---------------------------------------------------

	if @mode = 'delete'
	begin
		
		---------------------------------------------------
		-- delete the job
		---------------------------------------------------

		execute @result = DeleteNewAnalysisJob @jobNum, @msg output, @callingUser
		--
		if @result <> 0
		begin
			RAISERROR (@msg, 11, 1)
		end
		
		return 0
	end -- mode 'delete'
	
	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'reset'
	begin
		set @msg = 'Warning: the reset mode does not do anything in procedure DoAnalysisJobOperation'
		RAISERROR (@msg, 11, 3)
		
		return 0
	end -- mode 'reset'
	
	---------------------------------------------------
	-- Mode was unrecognized
	---------------------------------------------------
	
	set @msg = 'Mode "' + @mode +  '" was unrecognized'
	RAISERROR (@msg, 11, 2)

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[DoAnalysisJobOperation] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoAnalysisJobOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisJobOperation] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisJobOperation] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisJobOperation] TO [PNL\D3M580] AS [dbo]
GO
