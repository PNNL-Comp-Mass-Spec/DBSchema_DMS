/****** Object:  StoredProcedure [dbo].[GetResidueID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE GetResidueID
/****************************************************
**
**	Desc: Gets ResidueID for given Residue Symbol
**
**	Return values: 0: failure, otherwise, ResidueID
**
**	Parameters: 
**
**		Auth: kja
**		Date: 08/22/2004
**    
*****************************************************/
(
		@ResidueSymbol char(1)
)
As
	declare @ResidueID int
	set @ResidueID = 0
	
	SELECT @ResidueID = Residue_ID FROM T_Residues WHERE (Residue_Symbol = @ResidueSymbol)
	
	return @ResidueID

GO
GRANT VIEW DEFINITION ON [dbo].[GetResidueID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetResidueID] TO [PNL\D3M578] AS [dbo]
GO
