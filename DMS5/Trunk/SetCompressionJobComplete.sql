/****** Object:  StoredProcedure [dbo].[SetCompressionJobComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create Procedure SetCompressionJobComplete

/****************************************************
**
**	Desc: Sets status of FTICR compression job to 
**        successful completion
**        or sets status to failed (according to
**        value of input argument).
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	@DSNum					unique identifier for analysis job
**  @completionCode			0->success, 1->failure
**
**		Auth: dac
**		Date: 11/09/2001
**    
*****************************************************/
    @DSNum varchar(32),
    @completionCode int = 0
As
	-- set nocount on

	declare @DSID int

	set @DSID = convert(int, @DSNum)
	-- future: this could get more complicated

	-- future: get job and verify @processorName 

	-- future: check job state for "in progress"

	if @completionCode = 0
		begin
			UPDATE T_Dataset 
			SET DS_Compress_Date = GETDATE(), 
			DS_Comp_State = 1 -- "Compression complete" 
			WHERE (Dataset_ID = @DSID)
		end
	else
		begin
			UPDATE T_Dataset 
			Set DS_Comp_State = 2 -- "Compression failed" 
			WHERE (Dataset_ID = @DSID)
		end

	if @@rowcount <> 1
	begin
		RAISERROR ('Update operation failed',
			10, 1)
		return 53100
	end

	return 0
GO
GRANT VIEW DEFINITION ON [dbo].[SetCompressionJobComplete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetCompressionJobComplete] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetCompressionJobComplete] TO [PNL\D3M580] AS [dbo]
GO
