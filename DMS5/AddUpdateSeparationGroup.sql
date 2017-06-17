/****** Object:  StoredProcedure [dbo].[AddUpdateSeparationGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE AddUpdateSeparationGroup
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in T_Separation_Group 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	mem
**	Date:	06/12/2017 mem - Initial version
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@separationGroup varchar(64),
	@comment varchar(512),
	@active tinyint,
	@samplePrepVisible tinyint,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int = 0
	Declare @myRowCount int =0 

	Declare @datasetTypeID int
	
	Begin TRY 

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateSeparationGroup', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @comment = IsNull(@comment, '')
	Set @active = IsNull(@active, 0)
	Set @samplePrepVisible = IsNull(@samplePrepVisible, 0)

	Set @message = ''
	
	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	If @mode = 'update'
	Begin
		-- cannot update a non-existent entry
		--
		Declare @tmp varchar(64) = ''
		--
		SELECT @tmp = Sep_Group
		FROM  T_Separation_Group		
		WHERE (Sep_Group = @separationGroup)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0 OR @tmp = ''
			RAISERROR ('No entry could be found in database for update', 11, 16)
	End

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	--
	If @Mode = 'add'
	Begin

		INSERT INTO T_Separation_Group( Sep_Group,		                                
		                                [Comment],
		                                Active,
		                                Sample_Prep_Visible)
		VALUES(@separationGroup, @comment, @active, @samplePrepVisible)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
			RAISERROR ('Insert operation failed', 11, 7)

	End -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	If @Mode = 'update' 
	Begin
		set @myError = 0
		--
		UPDATE T_Separation_Group
		SET Comment = @comment,
		    Active = @active,
		    Sample_Prep_Visible = @samplePrepVisible
		WHERE (Sep_Group = @separationGroup)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @separationGroup)

	End -- update mode

	END TRY
	Begin CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'AddUpdateSeparationGroup'
	END CATCH

	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSeparationGroup] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateSeparationGroup] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSeparationGroup] TO [Limited_Table_Write] AS [dbo]
GO
