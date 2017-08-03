/****** Object:  StoredProcedure [dbo].[GetMassCorrectionID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetMassCorrectionID
/****************************************************
**
**	Desc: Gets Mass Correction ID for given ModSymbol
**
**	Return values: 0: failure, otherwise, MassCorrectionID
**
**	Auth:	kja
**	Date:	08/22/2004
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@modMass varchar(32)
)
As
	Set NoCount On
	
	Declare @MassCorrectionID int = 0
	Declare @MCVariance float = 0.00006
	
	SELECT @MassCorrectionID = Mass_Correction_ID
	FROM T_Mass_Correction_Factors
	WHERE (Monoisotopic_Mass_Correction < @modMass + @MCVariance AND
	       Monoisotopic_Mass_Correction > @modMass - @MCVariance)
	
	return @MassCorrectionID

GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionID] TO [Limited_Table_Write] AS [dbo]
GO
