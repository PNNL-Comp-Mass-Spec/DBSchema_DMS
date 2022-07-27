/****** Object:  StoredProcedure [dbo].[GetProteinCollectionID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetProteinCollectionID]
/****************************************************
**
**  Desc: Gets CollectionID for given FileName
**
**
**  Parameters: 
**
**  Auth:   kja
**  Date:   09/29/2004
**          06/26/2019 mem - Add comments and convert tabs to spaces
**          07/27/2022 mem - Switch from FileName to Collection_Name
**    
*****************************************************/
(
    @fileName varchar(128)  -- This is actually protein collection name, not the original .fasta file name
)
As
    Declare @Collection_ID Int = 0
    
    SELECT @Collection_ID = Protein_Collection_ID
    FROM T_Protein_Collections
    WHERE Collection_Name = @collectionName
    
    return @Collection_ID

GO
GRANT EXECUTE ON [dbo].[GetProteinCollectionID] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
