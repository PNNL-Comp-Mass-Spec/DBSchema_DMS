/****** Object:  UserDefinedFunction [dbo].[GetTaxIDChildCount] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetTaxIDChildCount]
/****************************************************
**
**	Desc:	Counts the number of nodes with Parent_Tax_ID equal to @TaxonomyID
**
**	Return value: integer; 0 if no children
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	03/02/2016 mem - Initial version
**    
*****************************************************/
(
	@TaxonomyID int
)
RETURNS varchar(4000)
AS
	BEGIN
		DECLARE @Children int = 0
				
		SELECT @Children = COUNT(*)
		FROM T_NCBI_Taxonomy_Nodes
		WHERE (Parent_Tax_ID = @TaxonomyID)
		
		RETURN @Children
	END


GO
