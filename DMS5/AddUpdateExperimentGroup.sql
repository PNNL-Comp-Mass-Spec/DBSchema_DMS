/****** Object:  StoredProcedure [dbo].[AddUpdateExperimentGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateExperimentGroup
/****************************************************
**
**  Desc: Adds new or edits existing Experiment Group
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	07/11/2006
**			09/13/2011 grk - Added Researcher
**			11/10/2011 grk - Removed character size limit from experiment list
**			11/10/2011 grk - Added Tab field
**			02/20/2013 mem - Now reporting invalid experiment names
**			06/13/2017 mem - Use SCOPE_IDENTITY
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**			08/18/2017 mem - Disable logging certain messages to T_Log_Entries
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@ID int output,
	@GroupType varchar(50),
	@Tab VARCHAR(128),				-- User-defined name for this experiment group, aka tag
	@Description varchar(512),
	@ExperimentList varchar(MAX),
	@ParentExp varchar(50),
	@Researcher VARCHAR(50),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0

	Set @message = ''

	Declare @logErrors tinyint = 0

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateExperimentGroup', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	---------------------------------------------------
	-- Resolve parent experiment name to ID
	---------------------------------------------------

	Declare @ParentExpID int
	Set @ParentExpID = 0
	--
	If @ParentExp <> ''
	Begin

		SELECT @ParentExpID = Exp_ID
		FROM T_Experiments
		WHERE Experiment_Num = @ParentExp
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			Set @logErrors = 1
			Set @message = 'Error trying to find existing entry'
			RAISERROR (@message, 10, 1)
			return 51004
		End
	End

	If @ParentExpID = 0
	Begin
		Set @ParentExpID = 15 -- "Placeholder" experiment NOTE: better to look it up
	End

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------
	Declare @tmp int

	If @mode = 'update'
	Begin
		-- cannot update a non-existent entry
		--
		Set @tmp = 0
		--
		SELECT @tmp = Group_ID
		FROM  T_Experiment_Groups
		WHERE (Group_ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			Set @logErrors = 1
			Set @message = 'Error trying to find existing entry'
			RAISERROR (@message, 10, 1)
			return 51004
		End

		If @tmp = 0
		Begin
			Set @message = 'Cannot update: entry does not exist in database'
			RAISERROR (@message, 10, 1)
			return 51004
		End
	End

	Set @logErrors = 1
	
	---------------------------------------------------
	-- create temporary table for experiments in list
	---------------------------------------------------
	--
	CREATE TABLE #XR (
	    Experiment_Num varchar(50),
	    Exp_ID         int
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @message = 'Failed to create temporary table for experiments'
		RAISERROR (@message, 10, 1)
		return 51219
	End

	---------------------------------------------------
	-- populate temporary table from list
	---------------------------------------------------
	--
	INSERT INTO #XR( Experiment_Num,
	                 Exp_ID )
	SELECT cast(Item AS varchar(50)) AS Experiment_Num,
	       0 AS Exp_ID
	FROM dbo.MakeTableFromList ( @ExperimentList )
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @message = 'Failed to populate temporary table for experiments'
		RAISERROR (@message, 10, 1)
		return 51219
	End


	---------------------------------------------------
	-- resolve experiment name to ID in temp table
	---------------------------------------------------

	UPDATE T
	SET T.Exp_ID = S.Exp_ID
	FROM #XR T
	     INNER JOIN T_Experiments S
	       ON T.Experiment_Num = S.Experiment_Num
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @message = 'Failed trying to resolve experiment IDs'
		RAISERROR (@message, 10, 1)
		return 51219
	End

	---------------------------------------------------
	-- check status of prospective member experiments
	---------------------------------------------------
	Declare @count int

	-- do all experiments in list actually exist?
	--
	Set @count = 0
	--
	SELECT @count = count(*)
	FROM #XR
	WHERE Exp_ID = 0
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @message = 'Failed trying to check existence of experiments in list'
		RAISERROR (@message, 10, 1)
		return 51219
	End

	If @count <> 0
	Begin
		Declare @InvalidExperiments varchar(256) = ''
		SELECT @InvalidExperiments = @InvalidExperiments + Experiment_Num + ','
		FROM #XR
		WHERE Exp_ID = 0

		-- Remove the trailing comma
		If @InvalidExperiments Like '%,'
			Set @InvalidExperiments = Substring(@InvalidExperiments, 1, Len(@InvalidExperiments)-1)
		
		Set @logErrors = 0
		Set @message = 'Experiment run list contains experiments that do not exist: ' + @InvalidExperiments
		RAISERROR (@message, 10, 1)
		return 51221
	End

	---------------------------------------------------
	-- Resolve researcher PRN
	---------------------------------------------------

	Declare @userID int
	execute @userID = GetUserID @researcher
	If @userID = 0
	Begin
		-- Could not find entry in database for PRN @researcher
		-- Try to auto-resolve the name

		Declare @MatchCount int
		Declare @NewPRN varchar(64)

		exec AutoResolveNameToPRN @researcher, @MatchCount output, @NewPRN output, @userID output

		If @MatchCount = 1
		Begin
			-- Single match found; update @researcher
			Set @researcher = @NewPRN
		End
		Else
		Begin
			Set @logErrors = 0
			Set @message = 'Could not find entry in database for researcher PRN "' + @researcher + '"'
			RAISERROR (@message, 10, 1)
			return 51037
		End

	End

	---------------------------------------------------
	-- start transaction
	--
	Declare @transName varchar(32)
	Set @transName = 'AddUpdateExperimentGroup'
	Begin transaction @transName

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	--
	If @Mode = 'add'
	Begin

		INSERT INTO T_Experiment_Groups (
			EG_Group_Type,
			EG_Created,
			EG_Description,
			Parent_Exp_ID,
			Researcher,
			Tab
		) VALUES (
			@GroupType, 
			getdate(), 
			@Description, 
			@ParentExpID, 
			@Researcher, 
			@Tab
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			rollback transaction @transName
			Set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
		End

		-- return ID of newly created entry
		--
		Set @ID = SCOPE_IDENTITY()

	End -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	If @Mode = 'update' 
	Begin
		Set @myError = 0
		--

		UPDATE T_Experiment_Groups
		SET EG_Group_Type = @GroupType,
		    EG_Description = @Description,
		    Parent_Exp_ID = @ParentExpID,
		    Researcher = @Researcher,
		    Tab = @Tab
		WHERE (Group_ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			rollback transaction @transName
			Set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 10, 1)
			return 51004
		End
	End -- update mode

	---------------------------------------------------
	-- update member experiments 
	---------------------------------------------------

	If @Mode = 'add' OR @Mode = 'update' 
	Begin
		-- remove any existing group members that are not in temporary table
		--
		DELETE FROM T_Experiment_Group_Members
		WHERE (Group_ID = @ID) AND
		      (Exp_ID NOT IN ( SELECT Exp_ID FROM #XR ))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			rollback transaction @transName
			Set @message = 'Failed trying to remove members from group'
			RAISERROR (@message, 10, 1)
		return 51004
		End
		    
		-- add group members from temporary table that are not already members
		--
		INSERT INTO T_Experiment_Group_Members(
			Group_ID,
			Exp_ID 
		)
		SELECT @ID,
		       #XR.Exp_ID
		FROM #XR
		WHERE #XR.Exp_ID NOT IN ( SELECT Exp_ID
		                          FROM T_Experiment_Group_Members
		                          WHERE Group_ID = @ID )
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			rollback transaction @transName
			Set @message = 'Failed trying to add members to group'
			RAISERROR (@message, 10, 1)
			return 51004
		End
	End

	commit transaction @transName
	
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperimentGroup] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperimentGroup] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperimentGroup] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperimentGroup] TO [Limited_Table_Write] AS [dbo]
GO
