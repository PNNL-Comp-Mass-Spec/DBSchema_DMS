/****** Object:  UserDefinedFunction [dbo].[GetJobRequestInstrList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetJobRequestInstrList]
/****************************************************
**
**	Desc: 
**      Builds a comma separated list of instruments for the datasets 
**      associated with the given analysis job request
**
**	Auth:   grk
**	Date:   11/01/2005 grk - Initial version
**          07/30/2019 mem - Get Dataset IDs from T_Analysis_Job_Request_Datasets
**    
*****************************************************/
(
    @requestID int
)
RETURNS varchar(1024)
AS
	BEGIN
		Declare @list varchar(1024) = ''
		
		SELECT 
			@list = @list + CASE 
								WHEN @list = '' THEN Instrument
								ELSE ', ' + Instrument
							END
		FROM 
		(
			SELECT DISTINCT InstName.IN_name As Instrument
			FROM T_Analysis_Job_Request_Datasets AJRD
			     INNER JOIN T_Dataset DS
			       ON AJRD.Dataset_ID = DS.Dataset_ID
			     INNER JOIN T_Instrument_Name InstName
			       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
			WHERE AJRD.Request_ID = @requestID
		) TX
		
		If @list = '' 
            Set @list = '(none)'

		RETURN @list
	END

GO
GRANT VIEW DEFINITION ON [dbo].[GetJobRequestInstrList] TO [DDL_Viewer] AS [dbo]
GO
