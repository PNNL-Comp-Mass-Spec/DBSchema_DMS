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
**	Parameters: 
**
**		Auth: kja
**		Date: 08/22/2004
**    
*****************************************************/
(
		@modMass varchar(32)
)
As
	declare @MassCorrectionID int
	set @MassCorrectionID = 0
	declare @MCVariance float
	set @MCVariance = 0.00006
	
	SELECT     @MassCorrectionID = Mass_Correction_ID
FROM         T_Mass_Correction_Factors
WHERE     (Monoisotopic_Mass_Correction < @modMass + @MCVariance AND Monoisotopic_Mass_Correction > @modMass - @MCVariance)			
	
	return(@MassCorrectionID)

GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionID] TO [PNL\D3M580] AS [dbo]
GO
