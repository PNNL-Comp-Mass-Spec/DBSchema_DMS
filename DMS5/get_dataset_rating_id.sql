/****** Object:  UserDefinedFunction [dbo].[get_dataset_rating_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dataset_rating_id]
/****************************************************
**
**  Desc: Gets datasetRatingID for given  DatasetRating name
**
**  Return values: 0: failure, otherwise, datasetRatingID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add set nocount on
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetRatingName varchar(80) = " "
)
RETURNS int
AS
BEGIN
    declare @datasetRatingID int = 0

    SELECT @datasetRatingID = DRN_state_ID
    FROM T_DatasetRatingName
    WHERE DRN_name = @datasetRatingName

    return @datasetRatingID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_rating_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_dataset_rating_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_rating_id] TO [Limited_Table_Write] AS [dbo]
GO
