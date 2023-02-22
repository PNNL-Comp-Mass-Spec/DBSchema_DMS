/****** Object:  UserDefinedFunction [dbo].[get_taxid_taxonomy_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_taxid_taxonomy_list]
/****************************************************
**
**  Desc:   Builds a delimited list of taxonomy information
**
**  Return value: List of items separated by vertical bars
**
**      Rank:Name:Tax_ID|Rank:Name:Tax_ID|Rank:Name:Tax_ID|
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/03/2016 mem - Added @ExtendedInfo
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @taxonomyID int,
    @extendedInfo tinyint
)
RETURNS varchar(4000)
AS
BEGIN
    Declare @list varchar(4000) = ''

    SELECT @list = @list + '|' +
                   [Rank] + ':' +
                   [Name]
    FROM dbo.get_taxid_taxonomy_table ( @TaxonomyID )
    WHERE Entry_ID = 1 OR
          [Rank] <> 'no rank' OR
          @ExtendedInfo > 0
    ORDER BY Entry_ID Desc

    Return Substring(@list, 2, 4000)

END

GO
GRANT VIEW DEFINITION ON [dbo].[get_taxid_taxonomy_list] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_taxid_taxonomy_list] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_taxid_taxonomy_list] TO [DMSReader] AS [dbo]
GO
