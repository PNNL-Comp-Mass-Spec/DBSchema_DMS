/****** Object:  UserDefinedFunction [dbo].[get_dataset_factor_count] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dataset_factor_count]
/****************************************************
**
**  Desc: Returns a count of the number of factors defined for this dataset
**
**  Auth:   mem
**  Date:   07/25/2017 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
