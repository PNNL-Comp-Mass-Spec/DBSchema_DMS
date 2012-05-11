/****** Object:  StoredProcedure [dbo].[PreviewRequestStepTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.PreviewRequestStepTask
/****************************************************
**
**	Desc: Previews the next step task that would be returned for a given processor
**
**	Auth:	mem
**			12/05/2008 mem
**			01/15/2009 mem - Updated to only display the job info if a job is assigned (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**			08/23/2010 mem - Added parameter @infoOnly
**
*****************************************************/
(
	@processorName varchar(128),
	@JobCountToPreview int = 10,	-- The number of jobs to preview
	@jobNumber int = 0 output,		-- Job number assigned; 0 if no job available
	@parameters varchar(max)='' output, -- job step parameters (in XML)
    @message varchar(512)='' output,
    @infoOnly tinyint = 1			-- 1 to preview the assigned task; 2 to preview the task and see extra status messages
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Set @infoOnly = IsNull(@infoOnly, 1)
	If @infoOnly < 1
		Set @infoOnly = 1
		
	Exec RequestStepTaskXML @processorName, 
							@jobNumber = @jobNumber output, 
							@parameters = @parameters output, 
							@message = @message output, 
							@infoonly = @infoOnly,
							@JobCountToPreview=@JobCountToPreview

	If Exists (Select * FROM T_Jobs WHERE Job = @JobNumber)
		SELECT @jobNumber AS JobNumber,
		       Dataset,
		       @ProcessorName AS Processor,
		       @parameters AS Parameters,
		       @message AS Message
		FROM T_Jobs
		WHERE Job = @JobNumber
	Else
		SELECT @message as Message

	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	--
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[PreviewRequestStepTask] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[PreviewRequestStepTask] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[PreviewRequestStepTask] TO [PNL\D3M580] AS [dbo]
GO
