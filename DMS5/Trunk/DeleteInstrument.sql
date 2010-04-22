/****** Object:  StoredProcedure [dbo].[DeleteInstrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure DeleteInstrument
/****************************************************
**
**	Desc:	Delete the specified instrument and associated storage path entries
**			Only allowed if no datasets exist for the instrument
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	02/12/2010
**    
*****************************************************/
(
	@InstrumentName varchar(32),
    @message varchar(512)='' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @InstrumentID int
	set @message = ''
	
	---------------------------------------------------
	-- Look up instrument ID for @InstrumentName
	---------------------------------------------------
	--
	set @InstrumentID = -1
	--
	SELECT @InstrumentID = Instrument_ID 
	FROM T_Instrument_Name 
	WHERE IN_name = @InstrumentName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @InstrumentID < 0
	Begin
		set @message = 'Instrument not found in T_Instrument_Name: ' + @InstrumentName
		RAISERROR (@message, 10, 1)
		return 51005
	End
	
	
	---------------------------------------------------
	-- Make sure no datasets exist yet for this instrument
	---------------------------------------------------
	
	Set @myRowCount = 0
	
	SELECT @myRowCount = COUNT(*)
	FROM T_Dataset
	WHERE (DS_instrument_name_ID = @InstrumentID)

	If @myRowCount > 0
	Begin
		set @message = 'Instrument ' + @InstrumentName + ' has ' + Convert(varchar(12), @myRowCount) + ' datasets in T_Dataset; deletion is not allowed'
		RAISERROR (@message, 10, 1)
		return 51006
	End
	
	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'DeleteInstrument'
	begin transaction @transName

	-- Delete associated dataset types
	DELETE T_Instrument_Allowed_Dataset_Type
	WHERE Instrument = @InstrumentName


	-- Delete archive path entry
	DELETE T_Archive_Path
	WHERE AP_instrument_name_ID = @InstrumentID
	

	-- Delete archive path entries
	DELETE FROM t_storage_path
	WHERE SP_instrument_name = @InstrumentName

	-- Delete instrument
	DELETE FROM T_Instrument_Name
	WHERE Instrument_ID = @InstrumentID

	
	---------------------------------------------------
	-- Finalize the transaction
	---------------------------------------------------
	--
	commit transaction @transName

	Set @message = 'Deleted instrument: ' + @InstrumentName
	Print @message
	
	return 0

GO
