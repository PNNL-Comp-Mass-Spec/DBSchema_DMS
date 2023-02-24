/****** Object:  StoredProcedure [dbo].[GetInstrumentName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetInstrumentName
/****************************************************
**
**	Desc: Gets InstrumentName for given instrument ID
**
**	Return values: "": failure, otherwise, instrument Name
**
**	Auth:	jds
**	Date:	07/01/2004
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@instrumentID int = 0
)
As
	Set NoCount On

	Declare @instrumentName varchar(80) = ' '
	
	SELECT @instrumentName = In_Name
	FROM T_Instrument_Name
	WHERE Instrument_ID = @instrumentID

	return @instrumentName
GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentName] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetInstrumentName] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentName] TO [Limited_Table_Write] AS [dbo]
GO
