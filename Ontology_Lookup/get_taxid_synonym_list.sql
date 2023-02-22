/****** Object:  UserDefinedFunction [dbo].[get_taxid_synonym_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_taxid_synonym_list]
/****************************************************
**
**  Desc:   Builds a delimited list of synonym names for the given Tax_ID value
**
**  Return value: comma-separated list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   03/01/2016 mem - Initial version
**          01/30/2023 mem - Use new view name
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @taxonomyID int
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
GRANT VIEW DEFINITION ON [dbo].[get_taxid_synonym_list] TO [DDL_Viewer] AS [dbo]
GO
