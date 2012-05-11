/****** Object:  StoredProcedure [dbo].[SetPreparationTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure SetPreparationTaskComplete
/****************************************************
**
**	Desc: Sets state of dataset record given by @datasetNum
**        to "completed".
**        Adjusts related database entries accordingly.
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth: grk
**	11/14/2002
**  09/25/2007 grk -- return result from DoDatasetCompletionActions (http://prismtrac.pnl.gov/trac/ticket/537)
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@completionCode int = 0, -- 0 -> success,  <> 0 -> failure
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @datasetID int
	declare @datasetState int
	declare @completionState int
	declare @result int
 
   	---------------------------------------------------
	-- choose completion state
	---------------------------------------------------
	
	if @completionCode = 0
		begin
			set @completionState = 3 -- normal completion
		end
	else
		begin
			set @completionState = 8 -- preparation failed
		end

   	---------------------------------------------------
	-- perform the actions necessary when dataset is complete
	---------------------------------------------------
	--
	execute @myError = DoDatasetCompletionActions @datasetNum, @completionState, @message output


   	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	if @message <> '' 
	begin
		RAISERROR (@message, 10, 1)
	end
	return @myError


GO
GRANT EXECUTE ON [dbo].[SetPreparationTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetPreparationTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetPreparationTaskComplete] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetPreparationTaskComplete] TO [PNL\D3M580] AS [dbo]
GO
