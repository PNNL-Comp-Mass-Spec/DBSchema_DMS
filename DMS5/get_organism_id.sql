/****** Object:  UserDefinedFunction [dbo].[get_organism_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_organism_id]
/****************************************************
**
**  Desc: Gets organismID for given organism name
**
**  Return values: 0: failure, otherwise, organismID
**
**  Auth:   grk
**  Date:   01/26/2001
**          09/25/2012 mem - Expanded @organismName to varchar(128)
**          08/03/2017 mem - Add Set NoCount On
**          12/19/2017 mem - Try matching field OG_Short_Name if no match to OG_name
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @organismName varchar(128) = ''
)
RETURNS int
AS
BEGIN
    Declare @organismID int = 0

    SELECT @organismID = Organism_ID
    FROM T_Organisms
    WHERE OG_name = @organismName

    If @organismID = 0
    Begin
        SELECT @organismID = Organism_ID
        FROM T_Organisms
        WHERE OG_Short_Name = @organismName
    End

    return @organismID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_organism_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_organism_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_organism_id] TO [Limited_Table_Write] AS [dbo]
GO
