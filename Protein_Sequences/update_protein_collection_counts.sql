/****** Object:  StoredProcedure [dbo].[UpdateProteinCollectionCounts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateProteinCollectionCounts
/****************************************************
**
**	Desc: Updates the protein and residue counts tracked in T_Protein_Collections for the given collection
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	09/14/2015 mem - Initial release
**    
*****************************************************/
(	
	@Collection_ID int,
	@NumProteins int,
	@NumResidues int,
	@message varchar(256)='' output
)

As
	declare @myError int = 0
	
	If Not Exists (SELECT * FROM T_Protein_Collections WHERE Protein_Collection_ID = @Collection_ID)
	Begin
		Set @message = 'Protein collection ID not found in T_Protein_Collections: ' + Cast(@Collection_ID as varchar(12))
		Set @myError = 15000
	End
	Else
	Begin
		UPDATE T_Protein_Collections
		SET NumProteins = @NumProteins,
			NumResidues = @NumResidues
		WHERE Protein_Collection_ID = @Collection_ID
		
		Set @message = 'Counts updated for Protein collection ID ' + Cast(@Collection_ID as varchar(12))
	End
		
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateProteinCollectionCounts] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
