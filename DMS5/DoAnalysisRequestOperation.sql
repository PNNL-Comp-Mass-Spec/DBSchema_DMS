/****** Object:  StoredProcedure [dbo].[DoAnalysisRequestOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoAnalysisRequestOperation
/****************************************************
**
**	Desc: 
**		Perform analysis request operation defined by 'mode'
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 10/13/2004
**		Date: 5/5/2005 grk - removed default mode value
**    
*****************************************************/
(
	@request varchar(32),
	@mode varchar(12),  -- 'delete', ??
    @message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
		
	declare @result int

	---------------------------------------------------
	-- Delete analysis job request if it is unused
	---------------------------------------------------

	if @mode = 'delete'
	begin
		
		declare @requestID int
		set @requestID = cast(@request as int)
		--
		execute @result = DeleteAnalysisRequest @requestID, @message output
		--
		if @result <> 0
		begin
			RAISERROR (@message, 10, 1)
			return 51142
		end

		return 0
	end -- mode 'deleteNew'
	
	
	---------------------------------------------------
	-- Mode was unrecognized
	---------------------------------------------------
	
	set @message = 'Mode "' + @mode +  '" was unrecognized'
	RAISERROR (@message, 10, 1)
	return 51222

GO
GRANT EXECUTE ON [dbo].[DoAnalysisRequestOperation] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoAnalysisRequestOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisRequestOperation] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisRequestOperation] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisRequestOperation] TO [PNL\D3M580] AS [dbo]
GO
