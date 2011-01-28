/****** Object:  StoredProcedure [dbo].[RequestResultsXferTaskParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestResultsXferTaskParams
/****************************************************
**
**	Desc: 
**	Finds parameters 
**	needed for transferring analysis job results from receiving 
**	folder to dataset folder.
**
**	All information needed for transfer task is returned
**	in the output arguments
**
**	Return values: 0: success, anything else: error
**
**	Auth: dac
**  5/11/2007 -- initial release
**	09/25/2007 grk - Rolled back to DMS from broker (http://prismtrac.pnl.gov/trac/ticket/537)
**    
*****************************************************/
	@EntityId int,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- Get parameters for this results task
	---------------------------------------------------

	declare @JobNum varchar(32)
	set @JobNum = cast(@EntityId as varchar(32))
	SELECT * 
	FROM V_RequestAnalysisResultsTask 
	WHERE Job = @JobNum
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Unable to retrieve job parameters'
		goto done
	end
	if @myRowCount <> 1 
	begin
		set @myError = 50005
		set @message = 'Invalid number of rows returned getting job params'
		goto done
	end
	
  	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RequestResultsXferTaskParams] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestResultsXferTaskParams] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestResultsXferTaskParams] TO [PNL\D3M580] AS [dbo]
GO
