/****** Object:  StoredProcedure [dbo].[GetInstrumentName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure GetInstrumentName
/****************************************************
**
**	Desc: Gets InstrumentName for given instrument ID
**
**	Return values: "": failure, otherwise, instrument Name
**
**	Parameters: 
**
**		Auth: jds
**		Date: 07/01/2004
**    
*****************************************************/
(
	@instrumentID int = 0
)
As
	declare @instrumentName varchar(80)
	set @instrumentName = ' '
	SELECT @instrumentName = In_Name FROM T_Instrument_Name WHERE (Instrument_ID = @instrumentID)
	return(@instrumentName)

GO
GRANT EXECUTE ON [dbo].[GetInstrumentName] TO [DMS_SP_User]
GO
