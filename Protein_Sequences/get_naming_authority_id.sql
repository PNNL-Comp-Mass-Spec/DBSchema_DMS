/****** Object:  StoredProcedure [dbo].[GetNamingAuthorityID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetNamingAuthorityID]
/****************************************************
**
**  Desc: Gets AuthorityID for a given Authority Name
**
**
**  Parameters:
**
**  Auth:   kja
**  Date:   12/16/2005
**
*****************************************************/
(
    @authName varchar(64)
)
AS
    declare @auth_id int
    set @auth_id = 0

    SELECT @auth_id = Authority_ID FROM T_Naming_Authorities
     WHERE ([Name] = @authName)

    return @auth_id

GO
GRANT EXECUTE ON [dbo].[GetNamingAuthorityID] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
