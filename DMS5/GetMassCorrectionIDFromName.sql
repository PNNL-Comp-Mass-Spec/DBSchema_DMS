/****** Object:  StoredProcedure [dbo].[GetMassCorrectionIDFromName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetMassCorrectionIDFromName]
/****************************************************
**
**	Desc: Gets Mass Correction ID for given Mass Correction Factor
**
**	Return values: 0: failure, otherwise, MassCorrectionID
**
**	Auth:	kja
**	Date:	08/22/2004
**			08/03/2017 mem - Add Set NoCount On
**          11/30/2018 mem - Rename Monoisotopic_Mass field
**    
*****************************************************/
(
	@modName char(8)
)
As
	Set NoCount On

	Declare @MassCorrectionID int = 0
		
	SELECT @MassCorrectionID = Mass_Correction_ID
	FROM T_Mass_Correction_Factors
	WHERE Mass_Correction_Tag = @modName		
	
	return @MassCorrectionID

GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionIDFromName] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionIDFromName] TO [Limited_Table_Write] AS [dbo]
GO
