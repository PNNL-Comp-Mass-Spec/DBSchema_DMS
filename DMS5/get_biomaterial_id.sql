/****** Object:  UserDefinedFunction [dbo].[get_biomaterial_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_biomaterial_id]
/****************************************************
**
**  Desc: Gets CC_ID for given biomaterial name
**
**  Return values: 0: failure, otherwise, campaign ID
**
**  Auth:   grk
**  Date:   03/26/2003
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @biomaterialName varchar(128) = " "
)
RETURNS int
AS
BEGIN
    Declare @ccID int = 0

    SELECT @ccID = CC_ID
    FROM T_Cell_Culture
    WHERE CC_Name = @biomaterialName

    return @ccID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_biomaterial_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_biomaterial_id] TO [Limited_Table_Write] AS [dbo]
GO
