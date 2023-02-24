/****** Object:  UserDefinedFunction [dbo].[get_enzyme_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_enzyme_id]
/****************************************************
**
**  Desc: Gets enzymeID for given enzyme name
**
**  Return values: 0: failure, otherwise, enzyme ID
**
**  Parameters:
**
**  Auth:   jds
**  Date:   08/25/2004
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @enzymeName varchar(50) = " "
)
RETURNS int
AS
BEGIN
    Declare @enzymeID int = 0

    SELECT @enzymeID = Enzyme_ID
    FROM T_Enzymes
    WHERE Enzyme_Name = @enzymeName

    return @enzymeID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_enzyme_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_enzyme_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_enzyme_id] TO [Limited_Table_Write] AS [dbo]
GO
