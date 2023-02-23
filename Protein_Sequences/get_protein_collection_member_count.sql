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
**  Parameters:
**
**  Auth:   kja
**  Date:   10/07/2004
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @collection_ID int
)
AS
    set nocount on

    declare @Collection_Member_Count int
    set @Collection_Member_Count = 0

SELECT @Collection_Member_Count = COUNT(*)
    FROM T_Protein_Collection_Members
    GROUP BY Protein_Collection_ID
    HAVING (Protein_Collection_ID = @Collection_ID)

    if @@rowcount = 0
    begin
        return 0
    end

    return(@Collection_Member_Count)

GO
GRANT EXECUTE ON [dbo].[get_protein_collection_member_count] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
