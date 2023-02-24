/****** Object:  UserDefinedFunction [dbo].[GetDatasetScanTypeList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetDatasetScanTypeList]
/****************************************************
**
**  Desc:
**      Builds a delimited list of actual scan types
**      for the specified dataset
**
**  Auth:   mem
**  Date:   05/13/2010
**          06/13/2022 mem - Convert from a table-valued function to a scalar-valued function
**
*****************************************************/
(
    @datasetID int
)
RETURNS varchar(1024)
AS
BEGIN
    Declare @list varchar(1024) = ''

    SELECT @list = @list + CASE WHEN @list = ''
                                THEN LookupQ.ScanType
                                ELSE ', ' + LookupQ.ScanType
                            END
    FROM (  SELECT DISTINCT ScanType
            FROM T_Dataset_ScanTypes
            WHERE Dataset_ID = @DatasetID
        ) LookupQ LEFT OUTER JOIN T_Dataset_ScanType_Glossary G
        ON LookupQ.ScanType = G.ScanType
    ORDER BY G.SortKey

    RETURN @list
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetScanTypeList] TO [DDL_Viewer] AS [dbo]
GO
