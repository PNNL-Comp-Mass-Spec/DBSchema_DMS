/****** Object:  UserDefinedFunction [dbo].[GetTaxIDSynonymList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetTaxIDSynonymList]
/****************************************************
**
**	Desc:	Builds a delimited list of synonym names for the given Tax_ID value
**
**	Return value: comma-separated list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	03/01/2016 mem - Initial version
**          01/30/2023 mem - Use new view name
**    
*****************************************************/
(
	@TaxonomyID int
)
RETURNS varchar(4000)
AS
	BEGIN
		declare @list varchar(4000) = null
		
		SELECT @list = Coalesce(@list + ', ' + [Synonym], [Synonym])
		FROM V_NCBI_Taxonomy_Alt_Name_List_Report
		WHERE Tax_ID = @TaxonomyID
		ORDER BY [Synonym]
		
		RETURN @list
	END


GO
GRANT VIEW DEFINITION ON [dbo].[GetTaxIDSynonymList] TO [DDL_Viewer] AS [dbo]
GO
