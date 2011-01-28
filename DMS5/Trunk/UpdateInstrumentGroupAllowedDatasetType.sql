/****** Object:  StoredProcedure [dbo].[UpdateInstrumentGroupAllowedDatasetType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateInstrumentGroupAllowedDatasetType
/****************************************************
**
**	Desc:
**      Adds, updates, or deletes allowed datset type for given instrument group
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	09/19/2009 grk - Initial release (Ticket #749, http://prismtrac.pnl.gov/trac/ticket/749)
**			02/12/2010 mem - Now making sure @DatasetType is properly capitalized
**			08/28/2010 mem - Updated to work with instrument groups
**
*****************************************************/
(
	@InstrumentGroup varchar(64),
	@DatasetType varchar(50),
	@Comment varchar(1024),
	@mode varchar(12) = 'add', -- or 'update' or 'delete'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @msg varchar(256)
	declare @ValidMode tinyint = 0
	
	BEGIN TRY 
	
	---------------------------------------------------
	-- Validate InstrumentGroup and DatasetType
	---------------------------------------------------
	--
	IF NOT EXISTS ( SELECT * FROM T_Instrument_Group WHERE IN_Group = @InstrumentGroup )
		RAISERROR ('Instrument group "%s" is not valid', 11, 12, @InstrumentGroup)

	IF NOT EXISTS ( SELECT * FROM T_DatasetTypeName WHERE DST_Name = @DatasetType ) 
		RAISERROR ('Dataset type "%s" is not valid', 11, 12, @DatasetType)
	
	---------------------------------------------------
	-- Make sure @DatasetType is properly capitalized
	---------------------------------------------------
	
	SELECT @DatasetType = DST_Name
	FROM T_DatasetTypeName
	WHERE DST_Name = @DatasetType
	
	---------------------------------------------------
	-- Does an entry already exist?
	---------------------------------------------------
	--
	DECLARE @exists VARCHAR(50)
	SET @exists = ''
	--
	SELECT @exists = IN_Group
	FROM T_Instrument_Group_Allowed_DS_Type
	WHERE IN_Group = @InstrumentGroup AND
		  Dataset_Type = @DatasetType

	---------------------------------------------------
	-- add mode
	---------------------------------------------------
	--
	IF @mode = 'add' 
	BEGIN --<add>
		IF @exists <> '' 
		BEGIN 
			SET @msg = 'Cannot add: Entry "' + @DatasetType + '" already exists for group ' + @InstrumentGroup
			RAISERROR (@msg, 11, 13)
		END 

		INSERT INTO T_Instrument_Group_Allowed_DS_Type ( IN_Group,
		                                                 Dataset_Type,
		                                                 Comment)
		VALUES(@InstrumentGroup, @DatasetType, @Comment)
		
		Set @ValidMode = 1
	END --<add>


	---------------------------------------------------
	-- update mode
	---------------------------------------------------
	--
	IF @mode = 'update' 
	BEGIN --<update>
		IF @exists = '' 
		BEGIN 
			SET @msg = 'Cannot Update: Entry "' + @DatasetType + '" does not exist for group ' + @InstrumentGroup
			RAISERROR (@msg, 11, 14)
		END 

		UPDATE T_Instrument_Group_Allowed_DS_Type
		SET Comment = @Comment
		WHERE (IN_Group = @InstrumentGroup) AND
		      (Dataset_Type = @DatasetType)

		Set @ValidMode = 1
	END --<update>

	---------------------------------------------------
	-- delete mode
	---------------------------------------------------
	--
	IF @mode = 'delete' 
	BEGIN --<delete>
		IF @exists = '' 
		BEGIN 
			SET @msg = 'Cannot Delete: Entry "' + @DatasetType + '" does not exist for group ' + @InstrumentGroup
			RAISERROR (@msg, 11, 15)
		END 

		DELETE FROM T_Instrument_Group_Allowed_DS_Type
		WHERE (IN_Group = @InstrumentGroup) AND
			  (Dataset_Type = @DatasetType)
		
		Set @ValidMode = 1
	END --<delete>
	
	If @ValidMode = 0
	Begin
		---------------------------------------------------
		-- unrecognized mode
		---------------------------------------------------

		SET @msg = 'Unrecognized Mode:' + @mode
		RAISERROR (@msg, 11, 16)
	End	

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH

	return @myError
	

GO
GRANT EXECUTE ON [dbo].[UpdateInstrumentGroupAllowedDatasetType] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateInstrumentGroupAllowedDatasetType] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateInstrumentGroupAllowedDatasetType] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateInstrumentGroupAllowedDatasetType] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateInstrumentGroupAllowedDatasetType] TO [PNL\D3M580] AS [dbo]
GO
