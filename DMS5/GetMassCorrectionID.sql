/****** Object:  StoredProcedure [dbo].[GetMassCorrectionID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetMassCorrectionID]
/****************************************************
**
**  Desc: Gets Mass Correction ID for given ModSymbol
**
**  Return values: 0: failure, otherwise, MassCorrectionID
**
**  Auth:   kja
**  Date:   08/22/2004
**          08/03/2017 mem - Add Set NoCount On
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          04/02/2020 mem - Change @modMass from a varchar to a float
**    
*****************************************************/
(
    @modMass float
)
As
    Set NoCount On
    
    Declare @MassCorrectionID int = 0
    Declare @MCVariance float = 0.00006
    
    SELECT @MassCorrectionID = Mass_Correction_ID
    FROM T_Mass_Correction_Factors
    WHERE (Monoisotopic_Mass < @modMass + @MCVariance AND
           Monoisotopic_Mass > @modMass - @MCVariance)
    
    return @MassCorrectionID

GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionID] TO [Limited_Table_Write] AS [dbo]
GO
