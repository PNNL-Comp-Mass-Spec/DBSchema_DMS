/****** Object:  StoredProcedure [dbo].[GetActiveInstrumentID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure GetActiveInstrumentID
/****************************************************
**
**	Desc: Gets the "Active" InstrumentID for given instrument name
**
**	Return values: 0: failure, otherwise, instrument ID
**
**	Parameters: Instrument Name - the name of the instrument
**
**		Auth: jds
**		Date: 6/28/2004
**    
*****************************************************/
(
	@instrumentName varchar(80) = " "
)
As
	declare @instrumentID int
	set @instrumentID = 0
	SELECT @instrumentID = Instrument_ID FROM T_Instrument_Name INNER JOIN T_Archive_Path ON Instrument_ID = AP_Instrument_Name_ID and IN_name = @instrumentName and AP_Function = 'Active'
	return(@instrumentID)

GO
GRANT EXECUTE ON [dbo].[GetActiveInstrumentID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetActiveInstrumentID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetActiveInstrumentID] TO [PNL\D3M578] AS [dbo]
GO
