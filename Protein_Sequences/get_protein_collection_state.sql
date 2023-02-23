/****** Object:  StoredProcedure [dbo].[get_protein_collection_state] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_protein_collection_state]
/****************************************************
**
**  Desc: Gets Collection State Name for given CollectionID
          Returns state 0 if the @Collection_ID does not exist
**
**
**  Parameters:
**
**  Auth:   kja
**  Date:   08/04/2005
**          09/14/2015 mem - Now returning "Unknown" if the protein collection ID does not exist in T_Protein_Collections
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @collection_ID int,
    @state_Name varchar(32) OUTPUT
)
AS
    declare @State_ID int

    set @State_ID = 0
    set @State_Name = 'Unknown'

    If Exists (Select * From T_Protein_Collections WHERE Protein_Collection_ID = @Collection_ID)
    Begin
        SELECT @State_ID = Collection_State_ID
        FROM T_Protein_Collections
        WHERE (Protein_Collection_ID = @Collection_ID)
    End

    SELECT @State_Name = State
    FROM T_Protein_Collection_States
    WHERE (Collection_State_ID = @State_ID)

    return 0

GO
GRANT EXECUTE ON [dbo].[get_protein_collection_state] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
