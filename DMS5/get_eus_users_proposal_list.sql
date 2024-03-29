/****** Object:  UserDefinedFunction [dbo].[get_eus_users_proposal_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_eus_users_proposal_list]
/****************************************************
**
**  Desc: Builds delimited list of proposals for
**            given EUS user
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   12/28/2008 mem - Initial version
**          09/15/2011 mem - Now excluding users with State_ID = 5
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @personID varchar(10)
)
RETURNS varchar(1024)
AS
BEGIN

    declare @list varchar(4096)
    set @list = ''

    SELECT
        @list = @list + CASE
        WHEN @list = '' THEN CAST(P.Proposal_ID AS varchar(12))
        ELSE ', ' + CAST(P.Proposal_ID AS varchar(12)) END
    FROM T_EUS_Proposal_Users P
    WHERE (Person_ID = @personID) AND P.State_ID <> 5


    RETURN @list
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_eus_users_proposal_list] TO [DDL_Viewer] AS [dbo]
GO
