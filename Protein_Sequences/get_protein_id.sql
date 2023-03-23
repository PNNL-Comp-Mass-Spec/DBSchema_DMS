/****** Object:  StoredProcedure [dbo].[get_protein_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_protein_id]
/****************************************************
**
**  Desc: Gets ProteinID for given length and SHA-1 Hash
**
**
**  Auth:   kja
**  Date:   10/06/2004
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @length int,
    @hash varchar(40)
)
AS
    declare @ProteinID int
    set @ProteinID = 0

    SELECT @ProteinID = Protein_ID FROM T_Proteins
     WHERE (Length = @length AND SHA1_Hash = @hash)

    return @ProteinID

GO
GRANT EXECUTE ON [dbo].[get_protein_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
