/****** Object:  StoredProcedure [dbo].[GetProteinID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE GetProteinID
/****************************************************
**
**	Desc: Gets ProteinID for given length and SHA-1 Hash
**
**
**	Parameters: 
**
**		Auth: kja
**		Date: 10/06/2004
**    
*****************************************************/
(
	@length int,
	@hash varchar(40)
)
As
	declare @Protein_ID int
	set @Protein_ID = 0
	
	SELECT @Protein_ID = Protein_ID FROM T_Proteins
	 WHERE (Length = @length AND SHA1_Hash = @hash)
	
	return @Protein_ID

GO
GRANT EXECUTE ON [dbo].[GetProteinID] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
