/****** Object:  StoredProcedure [dbo].[GetResidueID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetResidueID
/****************************************************
**
**	Desc: Gets ResidueID for given Residue Symbol
**
**	Return values: 0: failure, otherwise, ResidueID
**
**	Auth:	kja
**	Date:	08/22/2004
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@ResidueSymbol char(1)
)
As
	Set NoCount On
	
	Declare @ResidueID int = 0
	
	SELECT @ResidueID = Residue_ID
	FROM T_Residues
	WHERE Residue_Symbol = @ResidueSymbol
	
	return @ResidueID

GO
GRANT VIEW DEFINITION ON [dbo].[GetResidueID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetResidueID] TO [Limited_Table_Write] AS [dbo]
GO
