/****** Object:  StoredProcedure [dbo].[get_protein_id_from_name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_protein_id_from_name]
/****************************************************
**
**  Desc: Gets ProteinID for given Protein Name
**
**
**  Parameters:
**
**  Auth:   kja
**  Date:   12/07/2005
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @name varchar(128)
)
AS
    declare @protein_ID int

    SELECT TOP 1 @protein_ID = Protein_ID FROM T_Protein_Names
     WHERE [Name] = @name

    return @protein_ID

GO
GRANT EXECUTE ON [dbo].[get_protein_id_from_name] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
