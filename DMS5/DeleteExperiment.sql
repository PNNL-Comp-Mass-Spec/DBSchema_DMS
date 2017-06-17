/****** Object:  StoredProcedure [dbo].[DeleteExperiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.DeleteExperiment
/****************************************************
**
**	Desc: 
**  Deletes given Experiment from the Experiment table
**  and all referencing tables.  Experiment may not
**  have any associated datasets or requested runs
**
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	05/11/2004
**			06/16/2005 grk - added delete for experiment group members table
**			02/27/2006 grk - added delete for experiment group table
**			08/31/2006 jds - added check for requested runs (Ticket #199)
**			03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**			02/26/2010 mem - Merged T_Requested_Run_History with T_Requested_Run
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**    
*****************************************************/
(
	@ExperimentNum varchar(128),
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int = 0
	declare @myRowCount int = 0
	
	set @message = ''
	
	declare @ExperimentID int
	declare @state int
	
	declare @result int

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'DeleteExperiment', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End
	
	---------------------------------------------------
	-- get ExperimentID and current state
	---------------------------------------------------

	Set @ExperimentID = 0
	--
	SELECT @ExperimentID = Exp_ID
	FROM T_Experiments
	WHERE (Experiment_Num = @ExperimentNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @ExperimentID = 0
	begin
		set @message = 'Could not get Id for Experiment "' + @ExperimentNum + '"'
		RAISERROR (@message, 10, 1)
		return 51140
	end
	
	---------------------------------------------------
	-- Can't delete experiment that has any datasets
	---------------------------------------------------
	declare @dsCount int
	set @dsCount = 0
	--
	SELECT @dsCount = COUNT(*)
	FROM T_Dataset
	WHERE (Exp_ID = @ExperimentID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get dataset count for Experiment "' + @ExperimentNum + '"'
		RAISERROR (@message, 10, 1)
		return 51141
	end
	--
	if @dsCount > 0
	begin
		set @message = 'Cannot delete experiment that has associated datasets'
		RAISERROR (@message, 10, 1)
		return 51141
	end

	---------------------------------------------------
	-- Can't delete experiment that has a requested run
	---------------------------------------------------
	declare @rrCount int
	set @rrCount = 0
	--
	SELECT @rrCount = COUNT(*)
	FROM T_Requested_Run
	WHERE (Exp_ID = @ExperimentID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get requested run count for Experiment "' + @ExperimentNum + '"'
		RAISERROR (@message, 10, 1)
		return 51142
	end
	--
	if @rrCount > 0
	begin
		set @message = 'Cannot delete experiment that has associated requested runs'
		RAISERROR (@message, 10, 1)
		return 51142
	end

	---------------------------------------------------
	-- Can't delete experiment that has requested run history
	---------------------------------------------------
	declare @rrhCount int
	set @rrhCount = 0
	--
	SELECT @rrhCount = COUNT(*)
	FROM T_Requested_Run
	WHERE (Exp_ID = @ExperimentID) AND NOT (DatasetID IS NULL)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get requested run history count for Experiment "' + @ExperimentNum + '"'
		RAISERROR (@message, 10, 1)
		return 51143
	end
	--
	if @rrhCount > 0
	begin
		set @message = 'Cannot delete experiment that has associated requested run history'
		RAISERROR (@message, 10, 1)
		return 51143
	end

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteExperiment'
	begin transaction @transName
	
	---------------------------------------------------
	-- delete any entries for the Experiment from 
	-- cell culture map table
	---------------------------------------------------
	
	DELETE FROM T_Experiment_Cell_Cultures
	WHERE (Exp_ID = @ExperimentID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from cell culture association table was unsuccessful',
			10, 1)
		return 51130
	end

	---------------------------------------------------
	-- delete any entries for the Experiment from 
	-- experiment group map table
	---------------------------------------------------
	
	DELETE FROM T_Experiment_Group_Members
	WHERE (Exp_ID = @ExperimentID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from experiment group association table was unsuccessful',
			10, 1)
		return 51132
	end

	---------------------------------------------------
	-- remove any reference to this eperiment as parent
	-- experiment from experiment group table
	---------------------------------------------------
	
	UPDATE T_Experiment_Groups
	SET Parent_Exp_ID = 15
	WHERE (Parent_Exp_ID = @ExperimentID)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Resetting parent experiment from experiment group table was unsuccessful',
			10, 1)
		return 51134
	end

	---------------------------------------------------
	-- delete any auxiliary info associated with Experiment
	---------------------------------------------------
		
	exec @result = DeleteAuxInfo 'Experiment', @ExperimentNum, @message output

	if @result <> 0
	begin
		rollback transaction @transName
		set @message = 'Delete auxiliary information was unsuccessful for Experiment: ' + @message
		RAISERROR (@message, 10, 1)
		return 51136
	end
	
	---------------------------------------------------
	-- delete experiment from experiment table
	---------------------------------------------------

	DELETE FROM T_Experiments
	WHERE (Exp_ID = @ExperimentID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from Experiments table was unsuccessful',
			10, 1)
		return 51130
	end

	-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
	If Len(@callingUser) > 0
	Begin
		Declare @stateID int
		Set @stateID = 0

		Exec AlterEventLogEntryUser 3, @ExperimentID, @stateID, @callingUser
	End

	commit transaction @transName
	
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[DeleteExperiment] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteExperiment] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteExperiment] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteExperiment] TO [Limited_Table_Write] AS [dbo]
GO
