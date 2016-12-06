/****** Object:  UserDefinedFunction [dbo].[GetDatasetScanTypeList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.GetDatasetScanTypeList
/****************************************************
**
**	Desc: 
**		Builds a delimited list of actual scan types
**		for the specified dataset
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	05/13/2010
**    
*****************************************************/

(	
	@DatasetID int
)
RETURNS 
@TableOfResults TABLE 
(
	-- Add the column definitions for the TABLE variable here
	DatasetID int, 
	ScanTypeList varchar(3500)
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
                           WHEN @list = '' THEN LookupQ.ScanType
                           ELSE ', ' + LookupQ.ScanType
                       END
		FROM (	SELECT DISTINCT ScanType
				FROM T_Dataset_ScanTypes
				WHERE (Dataset_ID = @DatasetID) 
			) LookupQ LEFT OUTER JOIN T_Dataset_ScanType_Glossary G
			ON LookupQ.ScanType = G.ScanType
		ORDER BY G.SortKey


		INSERT INTO @TableOfResults(DatasetID, ScanTypeList)
		Values (@DatasetID, @List)
			
	RETURN 
END


GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetScanTypeList] TO [DDL_Viewer] AS [dbo]
GO
