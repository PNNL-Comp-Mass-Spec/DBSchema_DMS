/****** Object:  UserDefinedFunction [dbo].[get_residue_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_residue_id]
/****************************************************
**
**  Desc: Gets ResidueID for given Residue Symbol
**
**  Return values: 0: failure, otherwise, ResidueID
**
**  Auth:   kja
**  Date:   08/22/2004
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @residueSymbol char(1)
)
RETURNS int
AS
BEGIN
    Declare @ResidueID int = 0

    SELECT @ResidueID = Residue_ID
    FROM T_Residues
    WHERE Residue_Symbol = @residueSymbol

    return @ResidueID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_residue_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_residue_id] TO [Limited_Table_Write] AS [dbo]
GO
