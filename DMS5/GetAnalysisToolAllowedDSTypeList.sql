/****** Object:  UserDefinedFunction [dbo].[GetAnalysisToolAllowedDSTypeList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION GetAnalysisToolAllowedDSTypeList
/****************************************************
**
**	Desc: 
**		Builds a delimited list of allowed dataset types
**		for the given analysis tool
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	12/18/2009
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
	AllowedDatasetTypes varchar(3500)
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
		                           WHEN @list = '' THEN Dataset_Type
		                           ELSE ', ' + Dataset_Type
		                       END
		FROM T_Analysis_Tool_Allowed_Dataset_Type
		WHERE (Analysis_Tool_ID = @AnalysisToolID)
	
		INSERT INTO @TableOfResults(AnalysisToolID, AllowedDatasetTypes)
		Values (@AnalysisToolID, @List)
			
	RETURN 
END

GO
