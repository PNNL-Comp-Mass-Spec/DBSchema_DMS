/****** Object:  StoredProcedure [dbo].[GetProteinCollectionID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE GetProteinCollectionID
/****************************************************
**
**	Desc: Gets CollectionID for given FileName
**
**
**	Parameters: 
**
**		Auth: kja
**		Date: 9/29/2004
**    
*****************************************************/
(
	@fileName varchar(128)
)
As
	declare @Collection_ID int
	set @Collection_ID = 0
	
	SELECT @Collection_ID = Protein_Collection_ID FROM T_Protein_Collections
	 WHERE (FileName = @fileName)
	
	return @Collection_ID

GO
GRANT EXECUTE ON [dbo].[GetProteinCollectionID] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetProteinCollectionID] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
