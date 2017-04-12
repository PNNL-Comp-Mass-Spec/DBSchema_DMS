/****** Object:  StoredProcedure [dbo].[AddUpdateRunInterval] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateRunInterval
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_Run_Interval 
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
**   
*****************************************************/
(
	@ID INT OUTPUT ,
	@Comment varchar(MAX),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	Set @CallingUser = IsNull(@CallingUser, '')
	if @CallingUser = ''
		Set @CallingUser = suser_sname()

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 
	
	---------------------------------------------------
	-- validate usage and comment
	---------------------------------------------------
	
	DECLARE @usageXML XML
	DECLARE @cleanedComment VARCHAR(MAX) = @comment
	
	EXEC @myError = ParseUsageText @cleanedComment output, @usageXML output, @message output
	
	IF @myError <> 0
			RAISERROR (@message, 11, 10)

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
	if @Mode = 'update' 
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

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'AddUpdateRunInterval'
	END CATCH

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRunInterval] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRunInterval] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRunInterval] TO [DMS2_SP_User] AS [dbo]
GO
