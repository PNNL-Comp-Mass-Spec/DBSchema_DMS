/****** Object:  StoredProcedure [dbo].[get_protein_collection_member_count] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_protein_collection_member_count]
/****************************************************
**
**  Desc: Gets Collection Member count for given Collection_ID
**
**
**  Auth:   kja
**  Date:   10/07/2004
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @collectionID int
)
AS
    set nocount on

    Declare @CollectionMemberCount int = 0

    SELECT @CollectionMemberCount = COUNT(*)
    FROM T_Protein_Collection_Members
    GROUP BY Protein_Collection_ID
    HAVING (Protein_Collection_ID = @CollectionID)

    if @@rowcount = 0
    begin
        return 0
    end

    return (@CollectionMemberCount)

GO
GRANT EXECUTE ON [dbo].[get_protein_collection_member_count] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
