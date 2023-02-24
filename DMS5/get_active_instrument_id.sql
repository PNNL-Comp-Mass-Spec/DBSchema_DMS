/****** Object:  StoredProcedure [dbo].[GetActiveInstrumentID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetActiveInstrumentID
/****************************************************
**
**	Desc: Gets the "Active" InstrumentID for given instrument name
**
**	Return values: 0: failure, otherwise, instrument ID
**
**	Parameters: Instrument Name - the name of the instrument
**
**	Auth:	jds
**	Date:	06/28/2004
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@instrumentName varchar(80) = " "
)
As
	Set NoCount On

	Declare @instrumentID int = 0

	SELECT @instrumentID = Instrument_ID
	FROM T_Instrument_Name
	     INNER JOIN T_Archive_Path
	       ON Instrument_ID = AP_Instrument_Name_ID AND
	          IN_name = @instrumentName AND
	          AP_Function = 'Active'

	return @instrumentID

GO
GRANT VIEW DEFINITION ON [dbo].[GetActiveInstrumentID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetActiveInstrumentID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetActiveInstrumentID] TO [Limited_Table_Write] AS [dbo]
GO
