/****** Object:  UserDefinedFunction [dbo].[GetAnalysisToolAllowedInstClassList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION GetAnalysisToolAllowedInstClassList
/****************************************************
**
**	Desc: 
**		Builds a delimited list of allowed instrument class names
**		for the given analysis tool
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	11/12/2010
**    
*****************************************************/

(	
	@AnalysisToolID int
)
RETURNS 
@TableOfResults TABLE 
(
	-- Add the column definitions for the TABLE variable here
	AnalysisToolID int, 
	AllowedInstrumentClasses varchar(3500)
)
AS
BEGIN
	-- Fill the table variable with the rows for your result set

		declare @myRowCount int
		declare @myError int
		set @myRowCount = 0
		set @myError = 0

		declare @list varchar(3500)
		set @list = ''

		SELECT @list = @list + CASE
		                           WHEN @list = '' THEN Instrument_Class
		                           ELSE ', ' + Instrument_Class
		                       END
		FROM T_Analysis_Tool_Allowed_Instrument_Class
		WHERE (Analysis_Tool_ID = @AnalysisToolID)
	
		INSERT INTO @TableOfResults(AnalysisToolID, AllowedInstrumentClasses)
		Values (@AnalysisToolID, @List)
			
	RETURN 
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetAnalysisToolAllowedInstClassList] TO [DDL_Viewer] AS [dbo]
GO
