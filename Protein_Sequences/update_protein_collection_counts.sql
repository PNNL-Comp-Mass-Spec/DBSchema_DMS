/****** Object:  StoredProcedure [dbo].[update_protein_collection_counts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_protein_collection_counts]
/****************************************************
**
**  Desc: Updates the protein and residue counts tracked in T_Protein_Collections for the given collection
**
**  Auth:   mem
**  Date:   09/14/2015 mem - Initial release
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @collectionID int,
    @numProteins int,
    @numResidues int,
    @message varchar(256)='' output
)
AS
    declare @myError int = 0

    If Not Exists (SELECT * FROM T_Protein_Collections WHERE Protein_Collection_ID = @CollectionID)
    Begin
        Set @message = 'Protein collection ID not found in T_Protein_Collections: ' + Cast(@CollectionID as varchar(12))
        Set @myError = 15000
    End
    Else
    Begin
        UPDATE T_Protein_Collections
        SET NumProteins = @NumProteins,
            NumResidues = @NumResidues
        WHERE Protein_Collection_ID = @CollectionID

        Set @message = 'Counts updated for Protein collection ID ' + Cast(@CollectionID as varchar(12))
    End

    return @myError

GO
GRANT EXECUTE ON [dbo].[update_protein_collection_counts] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
