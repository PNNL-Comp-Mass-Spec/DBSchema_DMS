/****** Object:  UserDefinedFunction [dbo].[GetBatchDatasetInstrumentList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION GetBatchDatasetInstrumentList
/****************************************************
**
**	Desc: 
**  Builds delimited list of instruments for the 
**  datasets associated with the 
**  given requested run batch
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: mem
**		Date: 08/29/2010
**    
*****************************************************/
(
	@batchID int
)
RETURNS varchar(4000)
AS
BEGIN
	declare @list varchar(4000)
	set @list = ''
	
	SELECT @list = @list + CASE
	                           WHEN @list = '' THEN Instrument
	                           ELSE ', ' + Instrument
	                       END
	FROM ( SELECT DISTINCT InstName.IN_name AS Instrument
	       FROM T_Requested_Run RR
	            INNER JOIN T_Dataset DS
	              ON RR.DatasetID = DS.Dataset_ID
	            INNER JOIN T_Instrument_Name InstName
	              ON DS.DS_instrument_name_ID = InstName.Instrument_ID
	       WHERE RR.RDS_BatchID = @batchID ) LookupQ
	ORDER BY Instrument	

	RETURN @list
END


GO
