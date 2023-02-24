/****** Object:  UserDefinedFunction [dbo].[get_dataset_type_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dataset_type_id]
/****************************************************
**
**  Desc: Gets DatasetTypeID for given for given dataset type name
**
**  Return values: 0: failure, otherwise, campaign ID
**
**  Parameters:
**
**  Auth:   grk
**  Date:   01/26/2001
**          09/02/2010 mem - Expand @datasetType to varchar(50)
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetType varchar(50) = ''
)
RETURNS int
AS
BEGIN
    Declare @datasetTypeID int = 0

    SELECT @datasetTypeID = DST_Type_ID
    FROM T_DatasetTypeName
    WHERE DST_name = @datasetType

    return @datasetTypeID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_type_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_dataset_type_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_type_id] TO [Limited_Table_Write] AS [dbo]
GO
