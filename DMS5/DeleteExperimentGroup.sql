/****** Object:  StoredProcedure [dbo].[DeleteExperimentGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DeleteExperimentGroup
/****************************************************
**
**	Desc: 
**	Remove an experiment group (but not the experiments)
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 7/13/2006
**    
*****************************************************/
	@groupID int = 0,
	@message varchar(512)='' output
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
	set @transName = 'DeleteExperimentGroup'
	begin transaction @transName

	---------------------------------------------------
	-- 
	---------------------------------------------------

	DELETE FROM T_Experiment_Group_Members
	WHERE Group_ID = @groupID 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Failed to delete experiment group member entries'
		--RAISERROR (@message, 10, 1)
		return 51093
	end

	DELETE FROM T_Experiment_Groups
	WHERE Group_ID = @groupID 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Failed to delete experiment group entries'
		--RAISERROR (@message, 10, 1)
		return 51093
	end
	

	commit transaction @transName
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteExperimentGroup] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteExperimentGroup] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteExperimentGroup] TO [PNL\D3M580] AS [dbo]
GO
