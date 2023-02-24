/****** Object:  StoredProcedure [dbo].[update_taxonomy_item_if_defined] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_taxonomy_item_if_defined]
/****************************************************
**
**  Desc: This procedure is called via get_taxonomy_value_by_taxonomy_id
**        (Note that get_taxonomy_value_by_taxonomy_id is called by add_update_organisms when auto-defining taxonomy)
**
**  The calling procedure must create table #Tmp_TaxonomyInfo
**
**      CREATE TABLE #Tmp_TaxonomyInfo (
**          Entry_ID int not null,
**          [Rank] varchar(32) not null,
**          [Name] varchar(255) not null
**      )
**
**
**  Auth:   mem
**  Date:   03/02/2016
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @rank varchar(32),
    @value varchar(255) output      -- input/output variable
)
AS
    set nocount on

    Declare @TaxonomyName varchar(255) = ''

    SELECT @TaxonomyName = [Name]
    FROM  #Tmp_TaxonomyInfo
    WHERE [Rank] = @Rank

    If IsNull(@TaxonomyName, '') <> ''
        Set @Value = @TaxonomyName

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[update_taxonomy_item_if_defined] TO [DDL_Viewer] AS [dbo]
GO
