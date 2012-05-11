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
**		Auth: kja
**		Date: 10/08/2004
**
**		Changed for revised database architecture
**		kja 2005-11-28
**    
*****************************************************/
(
	@name varchar(128),
--	@description varchar(900),
--	@organism_ID int,
	@nameDescHash varchar(40)
)
As
	declare @reference_ID int
	set @reference_ID = 0

	SELECT @reference_ID = Reference_ID FROM T_Protein_Names
	 WHERE (Reference_Fingerprint = @nameDescHash)
	 
--	SELECT @reference_ID = Reference_ID FROM T_Protein_Names
--	 WHERE (Reference_Fingerprint = @nameDescHash AND Protein_ID = @protein_ID)
	 
--	 if @@rowcount > 1
--	 begin
--		SELECT @reference_ID = Reference_ID FROM T_Protein_Names
--	     WHERE ([Name] = @name AND Description = @description AND Protein_ID = @protein_ID)
--	 end
	
	return @reference_ID

GO
GRANT EXECUTE ON [dbo].[GetProteinReferenceID] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetProteinReferenceID] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
