/****** Object:  StoredProcedure [dbo].[GetInstrumentID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE Procedure GetInstrumentID
/****************************************************
**
**	Desc: Gets InstrumentID for given instrument name
**
**	Return values: 0: failure, otherwise, instrument ID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
(
	@instrumentName varchar(80) = " "
)
As
	declare @instrumentID int
	set @instrumentID = 0
	SELECT @instrumentID = Instrument_ID FROM T_Instrument_Name WHERE (IN_name = @instrumentName)
	return(@instrumentID)
GO
GRANT EXECUTE ON [dbo].[GetInstrumentID] TO [DMS_SP_User]
GO
