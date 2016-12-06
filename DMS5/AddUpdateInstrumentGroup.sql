/****** Object:  StoredProcedure [dbo].[AddUpdateInstrumentGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateInstrumentGroup
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in T_Instrument_Group 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	08/28/2010 grk - Initial version
**			08/30/2010 mem - Added parameters @Usage and @Comment
**			09/02/2010 mem - Added parameter @DefaultDatasetType
**			10/18/2012 mem - Added parameter @AllocationTag
**			02/23/2016 mem - Add set XACT_ABORT on
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@InstrumentGroup varchar(64),
	@Usage varchar(64),
	@Comment varchar(512),
	@Active tinyint,
	@AllocationTag varchar(24),
	@DefaultDatasetTypeName varchar(64),			-- This is allowed to be blank
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

	declare @datasetTypeID int
	
	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @message = ''
	Set @DefaultDatasetTypeName = IsNull(@DefaultDatasetTypeName, '')

	If @DefaultDatasetTypeName <> ''
		execute @datasetTypeID = GetDatasetTypeID @DefaultDatasetTypeName
	Else
		Set @datasetTypeID = 0
	
	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp varchar(64)
		set @tmp = ''
		--
		SELECT @tmp = IN_Group
		FROM  T_Instrument_Group		
		WHERE (IN_Group = @InstrumentGroup)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = ''
			RAISERROR ('No entry could be found in database for update', 11, 16)
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_Instrument_Group( IN_Group,
		                                Usage,
		                                Comment,
		                                Active,
		                                Allocation_Tag,
		                                Default_Dataset_Type )
		VALUES(@InstrumentGroup, @Usage, @Comment, @Active, @AllocationTag, CASE WHEN @datasetTypeID > 0 Then @datasetTypeID Else Null End )
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Insert operation failed', 11, 7)

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Instrument_Group
		SET Usage = @Usage,
		    Comment = @Comment,
		    Active = @Active,
		    Allocation_Tag = @AllocationTag,
		    Default_Dataset_Type = CASE WHEN @datasetTypeID > 0 Then @datasetTypeID Else Null End 
		WHERE (IN_Group = @InstrumentGroup)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @InstrumentGroup)

	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH

	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentGroup] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrumentGroup] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentGroup] TO [Limited_Table_Write] AS [dbo]
GO
