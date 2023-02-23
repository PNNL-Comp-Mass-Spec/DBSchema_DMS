/****** Object:  StoredProcedure [dbo].[get_protein_reference_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_protein_reference_id]
/****************************************************
**
**  Desc:   Gets CollectionID for given protein name description hash
**
**          As of July 2022, this procedure is no longer used, since the lookup query was moved to procedure add_protein_reference
**
**  Auth:   kja
**  Date:   10/08/2004
**          11/28/2005 kja - Changed for revised database architecture
**          12/11/2012 mem - Removed commented-out code
**          07/27/2022 mem - Removed protein name argument since unused
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @nameDescHash varchar(40)       -- SHA-1 hash of: proteinName + "_" + description + "_" + proteinId;
)
AS
    Declare @referenceID Int = 0

    SELECT @referenceID = Reference_ID
    FROM T_Protein_Names
    WHERE Reference_Fingerprint = @nameDescHash

    return @referenceID

GO
GRANT EXECUTE ON [dbo].[get_protein_reference_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
