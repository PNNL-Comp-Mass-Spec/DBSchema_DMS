/****** Object:  UserDefinedFunction [dbo].[GetInstrumentDatasetTypeList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION dbo.GetInstrumentDatasetTypeList
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
**    
*****************************************************/
(
	@InstrumentID int
)
RETURNS varchar(4000)
AS
	BEGIN
		declare @list varchar(4000)
		
		Set @list = ''
		
		SELECT @list = @list + ', ' + IADT.Dataset_Type
		FROM T_Instrument_Allowed_Dataset_Type AS IADT INNER JOIN
		     dbo.T_Instrument_Name AS InstName ON IADT.Instrument = InstName.IN_name
		WHERE InstName.Instrument_ID = @InstrumentID
		ORDER BY IADT.Dataset_Type

		-- Remove the leading two characters
		If Len(@list) > 0
			Set @list = Substring(@list, 3, Len(@list))
		
		RETURN @list
	END


GO
GRANT EXECUTE ON [dbo].[GetInstrumentDatasetTypeList] TO [D3L243] AS [dbo]
GO
