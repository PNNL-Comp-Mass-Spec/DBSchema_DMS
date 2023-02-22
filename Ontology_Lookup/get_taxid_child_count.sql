/****** Object:  UserDefinedFunction [dbo].[get_taxid_child_count] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_taxid_child_count]
/****************************************************
**
**  Desc:   Counts the number of nodes with Parent_Tax_ID equal to @TaxonomyID
**
**  Return value: integer; 0 if no children
**
**  Parameters:
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @taxonomyID int
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
GRANT VIEW DEFINITION ON [dbo].[get_taxid_child_count] TO [DDL_Viewer] AS [dbo]
GO
