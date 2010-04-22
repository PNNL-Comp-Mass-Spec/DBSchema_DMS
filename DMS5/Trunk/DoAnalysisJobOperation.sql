/****** Object:  StoredProcedure [dbo].[DoAnalysisJobOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.DoAnalysisJobOperation
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
**    
*****************************************************/
(
	@jobNum varchar(32),
	@mode varchar(12),  -- 'delete'
    @message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	declare @jobID int
	declare @state int
	
	declare @result int


	---------------------------------------------------
	-- Delete job if it is in "new" state only
	---------------------------------------------------

	if @mode = 'delete'
	begin
		
		---------------------------------------------------
		-- delete the job
		---------------------------------------------------

		execute @result = DeleteNewAnalysisJob @jobNum, @message output, @callingUser
		--
		if @result <> 0
		begin
			RAISERROR (@message, 10, 1)
			return 51142
		end

		return 0
	end -- mode 'deleteNew'
	
	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'reset'
	begin
		return 0
	end -- mode 'reset'
	
	---------------------------------------------------
	-- Mode was unrecognized
	---------------------------------------------------
	
	set @msg = 'Mode "' + @mode +  '" was unrecognized'
	RAISERROR (@msg, 10, 1)
	return 51222

GO
GRANT EXECUTE ON [dbo].[DoAnalysisJobOperation] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoAnalysisJobOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisJobOperation] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisJobOperation] TO [PNL\D3M580] AS [dbo]
GO
