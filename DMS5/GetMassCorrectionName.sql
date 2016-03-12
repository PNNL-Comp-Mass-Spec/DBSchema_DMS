/****** Object:  StoredProcedure [dbo].[GetMassCorrectionName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE GetMassCorrectionName
/****************************************************
**
**	Desc: Gets Mass Correction Name for given Mass Correction Factor
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
	declare @MassCorrectionName varchar(8)
		
	SELECT     @MassCorrectionName = Mass_Correction_Tag
		FROM         T_Mass_Correction_Factors
		WHERE     (Monoisotopic_Mass_Correction = @modMass)			
	
	return(@MassCorrectionName)

GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionName] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionName] TO [PNL\D3M578] AS [dbo]
GO
