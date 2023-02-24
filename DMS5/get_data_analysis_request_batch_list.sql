/****** Object:  UserDefinedFunction [dbo].[GetDataAnalysisRequestBatchList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetDataAnalysisRequestBatchList]
/****************************************************
**
**  Desc:
**      Builds delimited list of batch IDs
**      associated with the given data analysis request
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   03/25/2022 mem - Initial version
**
*****************************************************/
(
    @dataAnalysisRequestID int
)
RETURNS varchar(max)
AS
BEGIN
    Declare @list varchar(max) = ''

    SELECT @list = @list + CASE
                               WHEN @list = '' THEN cast(Batch_ID as varchar(12))
                               ELSE ', ' + cast(Batch_ID as varchar(12))
                           END
    FROM T_Data_Analysis_Request_Batch_IDs
    WHERE Request_ID = @dataAnalysisRequestID
    ORDER BY Batch_ID

    RETURN @list
END

GO
