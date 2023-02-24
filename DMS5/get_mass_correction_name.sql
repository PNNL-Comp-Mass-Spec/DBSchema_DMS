/****** Object:  UserDefinedFunction [dbo].[get_mass_correction_name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_mass_correction_name]
/****************************************************
**
**  Desc: Gets Mass Correction Name for given Mass Correction Factor
**
**  Return values: 0: failure, otherwise, MassCorrectionID
**
**  Auth:   kja
**  Date:   08/22/2004
**          08/03/2017 mem - Add Set NoCount On
**          11/30/2018 mem - Rename Monoisotopic_Mass field
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @modMass varchar(32)
)
RETURNS varchar(32)
AS
BEGIN
    Declare @MassCorrectionName varchar(8) = ''

    SELECT @MassCorrectionName = Mass_Correction_Tag
    FROM T_Mass_Correction_Factors
    WHERE Monoisotopic_Mass = @modMass

    return @MassCorrectionName
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_mass_correction_name] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_mass_correction_name] TO [Limited_Table_Write] AS [dbo]
GO
