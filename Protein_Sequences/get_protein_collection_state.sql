/****** Object:  StoredProcedure [dbo].[get_protein_collection_state] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_protein_collection_state]
/****************************************************
**
**  Desc: Gets Collection State Name for given CollectionID
          Returns state 0 if the @CollectionID does not exist
**
**
**  Auth:   kja
**  Date:   08/04/2005
**          09/14/2015 mem - Now returning "Unknown" if the protein collection ID does not exist in T_Protein_Collections
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @collectionID int,
    @stateName varchar(32) OUTPUT
)
AS
    declare @StateID int

    set @StateID = 0
    set @StateName = 'Unknown'

    If Exists (Select * From T_Protein_Collections WHERE Protein_Collection_ID = @CollectionID)
    Begin
        SELECT @StateID = Collection_State_ID
        FROM T_Protein_Collections
        WHERE (Protein_Collection_ID = @CollectionID)
    End

    SELECT @StateName = State
    FROM T_Protein_Collection_States
    WHERE (Collection_State_ID = @StateID)

    return 0

GO
GRANT EXECUTE ON [dbo].[get_protein_collection_state] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
