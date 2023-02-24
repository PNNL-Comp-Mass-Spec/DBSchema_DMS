/****** Object:  UserDefinedFunction [dbo].[GetDatasetFactorCount] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetDatasetFactorCount]
/****************************************************
**
**  Desc: Returns a count of the number of factors defined for this dataset
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

    SELECT @result = Factor_Count
    FROM V_Factor_Count_By_Dataset
    WHERE Dataset_ID = @datasetID

    RETURN IsNull(@result, 0)
END

GO
