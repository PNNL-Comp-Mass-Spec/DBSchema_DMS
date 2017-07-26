/****** Object:  UserDefinedFunction [dbo].[GetDatasetScanTypes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.GetDatasetScanTypes
/****************************************************
**
**	Desc: Returns a comma separated list of the dataset types for this dataset ID
**
**	Auth:	mem
**	Date:	07/25/2017 mem - Initial version
**    
*****************************************************/
(
	@datasetID INT
)
RETURNS varchar(3500)
AS
BEGIN
	DECLARE @list varchar(3500) = ''

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
	
	RETURN IsNull(@list, '')
END

GO
