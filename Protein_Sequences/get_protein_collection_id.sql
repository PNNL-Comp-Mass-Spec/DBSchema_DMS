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
**  Auth:   kja
**  Date:   09/29/2004
**          06/26/2019 mem - Add comments and convert tabs to spaces
**          07/27/2022 mem - Switch from FileName to Collection_Name
**                         - Rename argument to @collectionName
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
GRANT EXECUTE ON [dbo].[GetProteinCollectionID] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
