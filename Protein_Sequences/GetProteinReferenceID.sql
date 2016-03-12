/****** Object:  StoredProcedure [dbo].[GetProteinReferenceID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE GetProteinReferenceID
/****************************************************
**
**	Desc: Gets CollectionID for given FileName
**
**
**	Parameters: 
**
**	Auth:	kja
**	Date:	10/08/2004
**			11/28/2005 kja - Changed for revised database architecture
**			12/11/2012 mem - Removed commented-out code
**    
*****************************************************/
(
	@name varchar(128),
	@nameDescHash varchar(40)
)
As
	declare @reference_ID int
	set @reference_ID = 0

	SELECT @reference_ID = Reference_ID
	FROM T_Protein_Names
	WHERE (Reference_Fingerprint = @nameDescHash)

	return @reference_ID

GO
GRANT EXECUTE ON [dbo].[GetProteinReferenceID] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
