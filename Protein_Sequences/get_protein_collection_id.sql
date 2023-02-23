/****** Object:  StoredProcedure [dbo].[get_protein_collection_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_protein_collection_id]
/****************************************************
**
**  Desc: Gets CollectionID for given FileName
**
**  Auth:   kja
**  Date:   09/29/2004
**          06/26/2019 mem - Add comments and convert tabs to spaces
**          07/27/2022 mem - Switch from FileName to Collection_Name
**                         - Rename argument to @collectionName
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @collectionName varchar(128)
)
AS
    Declare @collectionID Int = 0

    SELECT @collectionID = Protein_Collection_ID
    FROM T_Protein_Collections
    WHERE Collection_Name = @collectionName

    return @collectionID

GO
GRANT EXECUTE ON [dbo].[get_protein_collection_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
