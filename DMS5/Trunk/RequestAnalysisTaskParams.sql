/****** Object:  StoredProcedure [dbo].[RequestAnalysisTaskParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestAnalysisTaskParams 
/****************************************************
**
**	Desc: 
**	Called by analysis manager
**  to get information that it needs to perform the task.
**
**	All information needed for task is returned
**	in the output resultset
**
**	Return values: 0: success, anything else: error
**
**		Auth: grk
**		Date: 12/17/2007  Initial release (http://prismtrac.pnl.gov/trac/ticket/588)
**    
**    Modifed:
**    
*****************************************************/
	@EntityId int,
	@message varchar(512) output
AS
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
	FROM V_RequestAnalysisJobEx5 
	WHERE JobNum = @EntityId
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Unable to retrieve analsis job parameters'
		goto done
	end
	if @myRowCount <> 1 
	begin
		set @myError = 50005
		set @message = 'Invalid number of rows returned getting analysis job params'
		goto done
	end
	
  	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
