/****** Object:  UserDefinedFunction [dbo].[GetNextInstrumentDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetNextInstrumentDataset
/****************************************************
**
**	Desc: 
**  Returns ID of first dataset
**  that was run on given instrument after given time
**
**	Return value: 
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	05/16/2011
**    
*****************************************************/
(
	@instrumentID INT,
	@start datetime
)
RETURNS INT 
AS
	BEGIN
		declare @result int
		set @result = 0

		SELECT TOP(1) @result = Dataset_ID
		FROM    dbo.T_Dataset
		WHERE   DS_instrument_name_ID = @instrumentID
				AND Acq_Time_Start > @start
		ORDER BY Acq_Time_Start

		RETURN @result
	END
GO
GRANT EXECUTE ON [dbo].[GetNextInstrumentDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetNextInstrumentDataset] TO [DMS2_SP_User] AS [dbo]
GO
