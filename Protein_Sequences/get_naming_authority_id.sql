/****** Object:  StoredProcedure [dbo].[get_naming_authority_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_naming_authority_id]
/****************************************************
**
**  Desc: Gets AuthorityID for a given Authority Name
**
**
**  Auth:   kja
**  Date:   12/16/2005
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @authName varchar(64)
)
AS
    declare @authId int
    set @authId = 0

    SELECT @authId = Authority_ID FROM T_Naming_Authorities
     WHERE ([Name] = @authName)

    return @authId

GO
GRANT EXECUTE ON [dbo].[get_naming_authority_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
