/****** Object:  UserDefinedFunction [dbo].[get_taxid_taxonomy_table] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_taxid_taxonomy_table]
/****************************************************
**
**  Desc:   Populates a table with the Taxonomy entries for the given TaxonomyID value
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
GRANT VIEW DEFINITION ON [dbo].[get_taxid_taxonomy_table] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[get_taxid_taxonomy_table] TO [DMS_SP_User] AS [dbo]
GO
GRANT SELECT ON [dbo].[get_taxid_taxonomy_table] TO [DMSReader] AS [dbo]
GO
