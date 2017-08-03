/****** Object:  StoredProcedure [dbo].[GetMassCorrectionName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetMassCorrectionName
/****************************************************
**
**	Desc: Gets Mass Correction Name for given Mass Correction Factor
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

	Declare @MassCorrectionName varchar(8) = ''
		
	SELECT @MassCorrectionName = Mass_Correction_Tag
	FROM T_Mass_Correction_Factors
	WHERE Monoisotopic_Mass_Correction = @modMass
	
	return @MassCorrectionName

GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionName] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMassCorrectionName] TO [Limited_Table_Write] AS [dbo]
GO
