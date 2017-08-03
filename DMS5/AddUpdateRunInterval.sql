/****** Object:  StoredProcedure [dbo].[AddUpdateRunInterval] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateRunInterval
/****************************************************
**
**  Desc: 
**		 Adds new or edits existing item in T_Run_Interval 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 02/15/2012 
**          02/15/2012 grk - modified percentage parameters
**          03/03/2012 grk - changed to embedded usage tags
**          03/07/2012 mem - Now populating Last_Affected and Entered_By
**          03/21/2012 grk - modified to handle modified ParseUsageText
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			04/28/2017 mem - Disable logging to T_Log_Entries when ParseUsageText reports an error
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**			08/02/2017 mem - @ID is no longer an output variable
**						   - Add parameters @showDebug and @invalidUsage
**						   - Pass @ID and @invalidUsage to ParseUsageText
**   
*****************************************************/
(
	@ID int ,
	@Comment varchar(MAX),				-- Usage comment, e.g. 'User[100%], Proposal[49521], PropUser[50151]'
	@mode varchar(12) = 'add',			-- 'add' or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = '',
	@showDebug tinyint = 0,
	@invalidUsage tinyint = 0 output	-- Set to 1 if the usage text in @comment cannot be parsed (or if the total percentage is not 100); UpdateRunOpLog uses this to skip invalid entries
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @ID = IsNull(@ID, -1)
	Set @message = ''
	Set @showDebug = IsNull(@showDebug, 0)
	Set @invalidUsage = 0
	
	Declare @logErrors tinyint = 0
	
	Set @CallingUser = IsNull(@CallingUser, '')
	if @CallingUser = ''
		Set @CallingUser = suser_sname()

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateRunInterval', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End
	
	BEGIN TRY 

	IF @ID < 0
	Begin
		Set @message = 'Invalid ID: ' + Cast(@id as varchar(9))
		RAISERROR (@message, 11, 10)
		Goto Done
	End
	
	---------------------------------------------------
	-- Validate usage and comment
	-- ParseUsageText looks for special usage tags in the comment and extracts that information, returning it as XML
	--
	-- If @comment is 'User[100%], Proposal[49361], PropUser[50082] Extra information about interval'
	-- after calling ParseUsageText, @cleanedComment will be 'Extra information about interval'
	-- and @usageXML will be <u User="100" Proposal="49361" PropUser="50082" />
	--
	-- If @comment only has 'User[100%], Proposal[49361], PropUser[50082]', then @cleanedComment will be empty after the call to ParseUsageText
	--
	-- Since @validateTotal is set to 1, if the percentages do not add up to 100%, ParseUsageText will raise an error (and @usageXML will be null)
	---------------------------------------------------
	
	DECLARE @usageXML XML
	DECLARE @cleanedComment VARCHAR(MAX) = @comment
	
	If @showDebug > 0
		print 'Calling ParseUsageText'
		
	EXEC @myError = ParseUsageText @cleanedComment output, @usageXML output, @message output, @seq=@ID, @showDebug=@showDebug, @validateTotal = 1, @invalidUsage=@invalidUsage output
	
	If @showDebug > 0
		print 'ParseUsageText returned ' + Cast(@myError as varchar(9))
		
	IF @myError <> 0
	Begin
		If @myError BETWEEN 1 and 255
			RAISERROR (@message, 11, @myError)
		Else
			RAISERROR (@message, 11, 12)
	End
	
	If @showDebug > 0
		print '@myError is 0 after ParseUsageText'
	
	Set @logErrors = 1
	
	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------
	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM  T_Run_Interval 
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 16)
	end


	---------------------------------------------------
	-- add mode is not supported
	---------------------------------------------------

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Run_Interval 
		SET
			Comment = @Comment,
			Usage = @usageXML,
			Last_Affected = GetDate(),
			Entered_By = @CallingUser
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
		
		If @logErrors > 0	
			Exec PostLogEntry 'Error', @message, 'AddUpdateRunInterval'
	END CATCH

Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRunInterval] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRunInterval] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRunInterval] TO [DMS2_SP_User] AS [dbo]
GO
