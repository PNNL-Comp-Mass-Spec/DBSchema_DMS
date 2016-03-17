/****** Object:  UserDefinedFunction [dbo].[GetTaxIDTaxonomyTable] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetTaxIDTaxonomyTable
/****************************************************
**
**	Desc:	Populates a table with the Taxonomy entries for the given TaxonomyID value
**
**	Auth:	mem
**	Date:	03/02/2016 mem - Initial version
**    
*****************************************************/
(
	@taxonomyID int
)
RETURNS @taxonomy TABLE
(
	[Rank] varchar(32) not NULL,
	[Name] varchar(255) NOT NULL,
	Tax_ID int NOT NULL,
	Entry_ID int NOT NULL identity(1,1)
)
AS
BEGIN

	Declare @parentTaxID int
	Declare @name varchar(255)
	Declare @rank varchar(32)

	While @taxonomyID <> 1
	Begin
	
		SELECT @parentTaxID = Parent_Tax_ID,
			@name = [Name],
			@rank = [Rank]
		FROM T_NCBI_Taxonomy_Cached
		WHERE T_NCBI_Taxonomy_Cached.Tax_ID = @taxonomyID

		If @@rowcount = 0
			Set @taxonomyID = 1
		Else
		Begin

			INSERT INTO @taxonomy ([Rank], [Name], Tax_ID)
			VALUES (@rank, @name, @taxonomyID)

			Set @taxonomyID = @parentTaxID
		End
	End

	RETURN
END



GO
GRANT SELECT ON [dbo].[GetTaxIDTaxonomyTable] TO [DMS_SP_User] AS [dbo]
GO
GRANT SELECT ON [dbo].[GetTaxIDTaxonomyTable] TO [DMSReader] AS [dbo]
GO
