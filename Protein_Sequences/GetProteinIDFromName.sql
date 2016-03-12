/****** Object:  StoredProcedure [dbo].[GetProteinIDFromName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetProteinIDFromName
/****************************************************
**
**	Desc: Gets ProteinID for given Protein Name
**
**
**	Parameters: 
**
**		Auth: kja
**		Date: 12/07/2005
**
*****************************************************/
(
	@name varchar(128)
)
As
	declare @protein_ID int
	
	SELECT TOP 1 @protein_ID = Protein_ID FROM T_Protein_Names
	 WHERE [Name] = @name
	 
	return @protein_ID

GO
GRANT EXECUTE ON [dbo].[GetProteinIDFromName] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
