/****** Object:  StoredProcedure [dbo].[UpdateInstrumentAllowedDatasetType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateInstrumentAllowedDatasetType
/****************************************************
**
**	Desc:
**      Adds, updates, or deletes allowed datset type for given instrument
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	09/19/2009 grk - Initial release (Ticket #749, http://prismtrac.pnl.gov/trac/ticket/749)
**			02/12/2010 mem - Now making sure @DatasetType is properly capitalized
**
*****************************************************/
(
	@Instrument varchar(24),
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
	
	---------------------------------------------------
	-- Is DatasetType valid?
	---------------------------------------------------
	--
	IF NOT EXISTS ( SELECT DST_Type_ID
					FROM T_DatasetTypeName
					WHERE DST_Name = @DatasetType ) 
	BEGIN
		SET @message = 'Dataset type "' + @DatasetType + '" is not valid'
		SET @myError = 221
		GOTO Done
	END
	
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
	SELECT @exists = Instrument
	FROM T_Instrument_Allowed_Dataset_Type
	WHERE Instrument = @Instrument AND
		Dataset_Type = @DatasetType



	---------------------------------------------------
	-- add mode
	---------------------------------------------------
	--
	IF @mode = 'add' 
	BEGIN --<add>
		IF @exists <> '' 
		BEGIN 
			SET @message = 'Cannot add: Entry "' + @DatasetType + '" already exists'
			SET @myError = 222
			GOTO Done
		END 

		INSERT INTO T_Instrument_Allowed_Dataset_Type( Instrument,
		                                               Dataset_Type,
		                                               Comment )
		VALUES (@Instrument, @DatasetType, @Comment)

		GOTO Done
	END --<add>

	---------------------------------------------------
	-- update mode
	---------------------------------------------------
	--
	IF @mode = 'update' 
	BEGIN --<update>
		IF @exists = '' 
		BEGIN 
			SET @message = 'Cannot Update: Entry "' + @DatasetType + '" does not exist'
			SET @myError = 223
			GOTO Done
		END 

		UPDATE T_Instrument_Allowed_Dataset_Type
		SET Comment = @Comment
		WHERE (Instrument = @Instrument) AND
		      (Dataset_Type = @DatasetType)
		      
		GOTO Done
	END --<update>

	---------------------------------------------------
	-- delete mode
	---------------------------------------------------
	--
	IF @mode = 'delete' 
	BEGIN --<delete>
		IF @exists = '' 
		BEGIN 
			SET @message = 'Cannot Delete: Entry "' + @DatasetType + '" does not exist'
			SET @myError = 223
			GOTO Done
		END 

		DELETE FROM T_Instrument_Allowed_Dataset_Type
		WHERE (Instrument = @Instrument) AND
			(Dataset_Type = @DatasetType)

		GOTO Done
	END --<delete>
	
	---------------------------------------------------
	-- unrecognized mode
	---------------------------------------------------

	SET @message = 'Unrecognized Mode:' + @mode
	SET @myError = 230
	
Done:
	return @myError
	

GO
GRANT EXECUTE ON [dbo].[UpdateInstrumentAllowedDatasetType] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateInstrumentAllowedDatasetType] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateInstrumentAllowedDatasetType] TO [PNL\D3M580] AS [dbo]
GO
