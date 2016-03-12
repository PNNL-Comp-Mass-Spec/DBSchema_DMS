/****** Object:  StoredProcedure [dbo].[GetMassCorrectionIDFromName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE GetMassCorrectionIDFromName
/****************************************************
**
**	Desc: Gets Mass Correction ID for given Mass Correction Factor
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
		@modName char(8)
)
As
	declare @MassCorrectionID int
		
	SELECT     @MassCorrectionID = Mass_Correction_ID
		FROM         T_Mass_Correction_Factors
		WHERE     (Mass_Correction_Tag = @modName)			
	
	return(@MassCorrectionID)

GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionIDFromName] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionIDFromName] TO [PNL\D3M578] AS [dbo]
GO
