/****** Object:  UserDefinedFunction [dbo].[get_research_team_user_role_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_research_team_user_role_list]
/****************************************************
**
**  Desc:
**  Builds a delimited list of roles
**  for given user for the given
**  research team
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/28/2010
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @researchTeamID int,
    @userID int
)
RETURNS varchar(256)
AS
    BEGIN
        declare @list varchar(256)
        DECLARE @sep VARCHAR(8)
        SET @sep = '|'
        set @list = ''

        SELECT
          @list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END +  T_Research_Team_Roles.Role
        FROM
          T_Research_Team_Roles
          INNER JOIN T_Research_Team_Membership ON T_Research_Team_Roles.ID = T_Research_Team_Membership.Role_ID
        WHERE
          ( T_Research_Team_Membership.Team_ID = @researchTeamID )
          AND ( T_Research_Team_Membership.User_ID = @userID )

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_research_team_user_role_list] TO [DDL_Viewer] AS [dbo]
GO
