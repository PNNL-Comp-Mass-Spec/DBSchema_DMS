/****** Object:  StoredProcedure [dbo].[RequestDataExtractionTaskParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestDataExtractionTaskParams
/****************************************************
**
**	Desc: 
**	Updates job table to show job is in progress, and finds parameters 
**		needed for performing data extraction
**
**	All information needed for extraction task is returned
**	in the output arguments
**
**	Return values: 0: success, anything else: error
**
**	Auth: dac
**	06/26/2007 -- initial release
**	08/01/2007 dac - Added processor name parameter
**	09/25/2007 grk - Rolled back to DMS from broker (http://prismtrac.pnl.gov/trac/ticket/537)
**	11/01/2007 mem - No longer updating the State field in T_Analysis_Job (Ticket #569)
**
*****************************************************/
(
	@EntityId int,
  	@DemProcessorName varchar(64),
	@message varchar(512)='' output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	---------------------------------------------------
	-- Update job status
	---------------------------------------------------
	set @myError = 0
	set @myRowCount = 0
	
	UPDATE T_Analysis_Job 
	SET AJ_finish = GETDATE(),
		AJ_extractionProcessor = @DemProcessorName
	WHERE (AJ_jobID = @EntityId)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Update operation failed'
		goto done
	end

	---------------------------------------------------
	-- Get parameters for this extraction task
	---------------------------------------------------

	SELECT * 
	FROM V_RequestDataExtractionTaskParams
	WHERE JobID = @EntityId
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Unable to retrieve task parameters'
		goto done
	end
	if @myRowCount <> 1 
	begin
		set @myError = 50005
		set @message = 'Invalid number of rows returned getting task params'
		goto done
	end
	
  	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
