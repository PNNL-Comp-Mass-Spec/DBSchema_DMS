/****** Object:  UserDefinedFunction [dbo].[GetRunRequestInstrList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION GetRunRequestInstrList
/****************************************************
**
**	Desc: 
**  Builds delimited list of instruments
**  for the dataset list for the given analysis job request
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 11/0/2005
**    
*****************************************************/
(
@requestID int
)
RETURNS varchar(1024)
AS
	BEGIN
		declare @list varchar(1024)
		set @list = ''
		
		SELECT 
			@list = @list + CASE 
								WHEN @list = '' THEN Instrument
								ELSE ', ' + Instrument
							END
		FROM 
		(
			SELECT Distinct Instrument
			FROM V_dataset_report
			WHERE Dataset IN
			(
				SELECT     *
				FROM GetRunRequestDatasetList(@requestID)
			)
		) TX
		
		if @list = '' set @list = '(none)'

		RETURN @list
	END

GO
