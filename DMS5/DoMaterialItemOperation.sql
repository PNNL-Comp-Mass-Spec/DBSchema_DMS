/****** Object:  StoredProcedure [dbo].[DoMaterialItemOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoMaterialItemOperation
/****************************************************
**
**  Desc: Do an operation on an item, using the item name
**
**  Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	07/23/2008 grk - Initial version (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**			10/01/2009 mem - Expanded error message
**			08/19/2010 grk - try-catch for error handling
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
(
	@name varchar(128),					-- Item name (either biomaterial or an experiment)
	@mode varchar(32),					-- 'retire_biomaterial', 'retire_experiment'
    @message varchar(512) output,
	@callingUser varchar (128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0
	
	set @message = ''
    declare @msg varchar(512)

	BEGIN TRY 

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'DoMaterialItemOperation', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End

	---------------------------------------------------
	-- convert name to ID
	---------------------------------------------------
	declare @tmpID int
	set @tmpID = 0
	--
	declare @type_tag varchar(2)
	set @type_tag = ''
	--

	if @mode = 'retire_biomaterial'
	begin
		-- look up ID from name from cell culture
		set @type_tag = 'B'
		--
		SELECT @tmpID = CC_ID
		FROM T_Cell_Culture
		WHERE CC_Name = @name	
	end
	if @mode = 'retire_experiment'
	begin
		-- look up ID from name from experiment
		set @type_tag = 'E'
		--
		SELECT @tmpID = Exp_ID
		FROM T_Experiments
		WHERE Experiment_Num = @name
	end
	
	---------------------------------------------------
	-- call the material update function
	---------------------------------------------------
	--
	if @tmpID = 0
	begin
		set @msg = 'Could not find the material item for @mode="' + @mode + '" and @name="' + @name + '"'
		RAISERROR (@msg, 11, 1)
	end
	else
	begin
		declare 
			@iMode varchar(32),
			@itemList varchar(4096),
			@itemType varchar(128),
			@newValue varchar(128),
			@comment varchar(512)

			set @iMode = 'retire_items'
			set @itemList  = @type_tag + ':' + convert(varchar, @tmpID)
			set @itemType  = 'mixed_material'
			set @newValue  = ''
			set @comment  = ''

		exec @myError = UpdateMaterialItems
				@iMode,			-- 'retire_item'
				@itemList,
				@itemType,		-- 'mixed_material'
				@newValue,
				@comment,
				@msg output,
   				@callingUser
		
		if @myError <> 0
		begin
			RAISERROR (@msg, 11, 1)
		end
	end

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'DoMaterialItemOperation'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialItemOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoMaterialItemOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialItemOperation] TO [Limited_Table_Write] AS [dbo]
GO
