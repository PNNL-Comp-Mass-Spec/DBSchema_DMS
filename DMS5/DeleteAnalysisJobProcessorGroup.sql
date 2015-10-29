/****** Object:  StoredProcedure [dbo].[DeleteAnalysisJobProcessorGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Procedure dbo.DeleteAnalysisJobProcessorGroup
/****************************************************
**
**	Desc: 
**	Remove an analysis job processor Group (and all its dependencies)
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 03/06/2007
**    
*****************************************************/
	@groupID int = 0,
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
	set @transName = 'DeleteAnalysisJobProcessorGroup'
	begin transaction @transName

	---------------------------------------------------
	-- T_Analysis_Job_Processor_Group_Associations
	---------------------------------------------------

	DELETE FROM T_Analysis_Job_Processor_Group_Associations
	WHERE     (Group_ID = @groupID)

	---------------------------------------------------
	-- T_Analysis_Job_Processor_Group_Membership
	---------------------------------------------------

	DELETE FROM T_Analysis_Job_Processor_Group_Membership
	WHERE     (Group_ID = @groupID)

	---------------------------------------------------
	-- T_Analysis_Job_Processor_Group
	---------------------------------------------------

	DELETE FROM T_Analysis_Job_Processor_Group
	WHERE (ID = @groupID)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	--rollback transaction @transName

	commit transaction @transName
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJobProcessorGroup] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJobProcessorGroup] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisJobProcessorGroup] TO [PNL\D3M580] AS [dbo]
GO
