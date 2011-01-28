/****** Object:  StoredProcedure [dbo].[RequestPreparationTaskParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestPreparationTaskParams
/****************************************************
**
**	Desc: 
**	Called by prep manager to update dataset status and
**  to get information that it needs to perform the task.
**
**	All information needed for task is returned
**	in the output resultset
**
**	Return values: 0: success, anything else: error
**
**		Auth: dac
**		Date: 09/21/2007
**    
**    Modifed:
**		09/25/2007 grl - Rolled back to DMS from broker (http://prismtrac.pnl.gov/trac/ticket/537)
**    
*****************************************************/
	@EntityId int,
--	@PrepServerName varchar(64),
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- Get parameters for this task
	---------------------------------------------------
	--
	SELECT * 
	FROM V_GetPreparationTaskParams 
	WHERE Dataset_ID = @EntityId
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Unable to retrieve dataset parameters'
		goto done
	end
	if @myRowCount <> 1 
	begin
		set @myError = 50005
		set @message = 'Invalid number of rows returned getting dataset params'
		goto done
	end
	
  	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RequestPreparationTaskParams] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPreparationTaskParams] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPreparationTaskParams] TO [PNL\D3M580] AS [dbo]
GO
