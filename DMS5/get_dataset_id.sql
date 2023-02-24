/****** Object:  UserDefinedFunction [dbo].[get_dataset_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dataset_id]
/****************************************************
**
**  Desc: Gets datasetID for given dataset name
**
**  Return values: 0: failure, otherwise, dataset ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetName varchar(80) = " "
)
RETURNS int
AS
BEGIN
    Declare @datasetID int = 0

    SELECT @datasetID = Dataset_ID
    FROM T_Dataset
    WHERE Dataset_Num = @datasetName

    return(@datasetID)
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_dataset_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_dataset_id] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_id] TO [Limited_Table_Write] AS [dbo]
GO
