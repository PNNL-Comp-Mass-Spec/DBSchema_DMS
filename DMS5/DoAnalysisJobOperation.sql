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
**		Auth: grk
**		Date: 5/2/2002
**		Date: 5/5/2005 grk - removed default mode value
**    
*****************************************************/
(
	@jobNum varchar(32),
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

		execute @result = DeleteNewAnalysisJob @jobNum, @message output
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
GRANT EXECUTE ON [dbo].[DoAnalysisJobOperation] TO [DMS_Analysis]
GO
