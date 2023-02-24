/****** Object:  UserDefinedFunction [dbo].[GetInstrumentDatasetTypeList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetInstrumentDatasetTypeList]
/****************************************************
**
**	Desc: 
**  Builds delimited list of allowed dataset types
**  for given instrument ID
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	09/17/2009 mem - Initial version (Ticket #748)
**			08/28/2010 mem - Updated to use GetInstrumentGroupDatasetTypeList
**          02/04/2021 mem - Provide a delimiter when calling GetInstrumentGroupDatasetTypeList
**    
*****************************************************/
(
	@InstrumentID int
)
RETURNS varchar(4000)
AS
	BEGIN
		declare @list varchar(4000) = ''
		Declare @InstrumentGroup varchar(64) = ''
		
		-- Lookup the instrument group for this instrument
		
		SELECT @InstrumentGroup = IN_Group
		FROM T_Instrument_Name
		WHERE Instrument_ID = @InstrumentID
		
		IF @InstrumentGroup <> ''
			SELECT @list = dbo.GetInstrumentGroupDatasetTypeList(@InstrumentGroup, ', ')

		RETURN @list
	END


GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentDatasetTypeList] TO [DDL_Viewer] AS [dbo]
GO
