/****** Object:  UserDefinedFunction [dbo].[GetDatasetPredefineJobCount] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetDatasetPredefineJobCount]
/****************************************************
**
**  Desc: Returns a count of the number of predefined jobs created for this dataset
**
**  Auth:   mem
**  Date:   07/25/2017 mem - Initial version
**
*****************************************************/
(
    @datasetID INT
)
RETURNS int
AS
BEGIN
    DECLARE @result int

    SELECT @result = SUM(jobs_created)
    FROM T_Predefined_Analysis_Scheduling_Queue
    WHERE Dataset_ID = @datasetID

    RETURN IsNull(@result, 0)
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetPredefineJobCount] TO [DDL_Viewer] AS [dbo]
GO
