/****** Object:  UserDefinedFunction [dbo].[GetResearchTeamMembershipList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetResearchTeamMembershipList
/****************************************************
**
**	Desc: 
**  Builds a delimited list of role:person pairs
**  for the given research team
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	02/03/2010
**    
*****************************************************/
(
	@researchTeamID int
)
RETURNS varchar(6000)
AS
	BEGIN
		declare @list varchar(6000)
		DECLARE @sep VARCHAR(8)
		SET @sep = '|'
		set @list = ''

		SELECT
			@list = @list + CASE WHEN @list = '' THEN '' ELSE @sep END +  
			T_Research_Team_Roles.Role + ':' + T_Users.U_Name + ' (' + T_Users.U_PRN + ')'
		FROM
			T_Research_Team_Roles
			INNER JOIN T_Research_Team_Membership ON T_Research_Team_Roles.ID = T_Research_Team_Membership.Role_ID
			INNER JOIN T_Users ON T_Research_Team_Membership.User_ID = T_Users.ID
		WHERE
			T_Research_Team_Membership.Team_ID = @researchTeamID
	
		RETURN @list
	END
GO
