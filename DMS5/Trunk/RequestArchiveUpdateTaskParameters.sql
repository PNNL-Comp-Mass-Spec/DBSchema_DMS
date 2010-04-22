/****** Object:  StoredProcedure [dbo].[RequestArchiveUpdateTaskParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.RequestArchiveUpdateTaskParameters 
/****************************************************
**
**	Desc: 
**	Called by archive manager to 
**  to get information that it needs to perform the task.
**
**	All information needed for task is returned
**	in the output resultset
**
**	Return values: 0: success, anything else: error
**
**	Auth: grk
**	09/25/2007 -- initial release (http://prismtrac.pnl.gov/trac/ticket/537)
**    
**    Modifed:
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
	-- Get parameters for this task
	---------------------------------------------------
	--
	SELECT * 
	FROM V_GetDatasetsForArchiveUpdateTask 
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
/**/	
  	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RequestArchiveUpdateTaskParameters] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestArchiveUpdateTaskParameters] TO [PNL\D3M580] AS [dbo]
GO
