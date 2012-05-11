/****** Object:  StoredProcedure [dbo].[DeleteAnalysisJobProcessor] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Procedure dbo.DeleteAnalysisJobProcessor
/****************************************************
**
**	Desc: 
**	Remove an analysis job processor (and all its dependencies)
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 03/05/2007
**    
*****************************************************/
	@processorID int = 0,
	@message varchar(512) output
As
	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	declare @msg varchar(256)

	
	---------------------------------------------------
	-- 
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteAnalysisJobProcessor'
	begin transaction @transName

	---------------------------------------------------
	-- T_Analysis_Job_Processor_Tools
	---------------------------------------------------

	DELETE FROM T_Analysis_Job_Processor_Tools
	WHERE     (Processor_ID = @processorID)

	---------------------------------------------------
	-- T_Analysis_Job_Processor_Group_Membership
	---------------------------------------------------

	DELETE FROM T_Analysis_Job_Processor_Group_Membership
	WHERE     (Processor_ID = @processorID)

	---------------------------------------------------
	-- T_Analysis_Job_Processors
	---------------------------------------------------

	DELETE FROM T_Analysis_Job_Processors
	WHERE (ID = @processorID)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	--rollback transaction @transName

	commit transaction @transName
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJobProcessor] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJobProcessor] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJobProcessor] TO [PNL\D3M580] AS [dbo]
GO
