/****** Object:  UserDefinedFunction [dbo].[GetCampaignRolePerson] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetCampaignRolePerson
/****************************************************
**
**	Desc: 
**  Returns person for given role
**  for the given campaign
**
**	Return value: person
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	02/03/2010
**			12/08/2014 mem - Now using Name_with_PRN to obtain the user's name and PRN
**    
*****************************************************/
(
	@campaignID INT,
	@role VARCHAR(64)
)
RETURNS varchar(128)
AS
	BEGIN
		declare @result varchar(6000)
		set @result = ''

		IF NOT (@campaignID IS NULL OR @role IS NULL)
		BEGIN	
			SELECT @result = T_Users.Name_with_PRN
			FROM T_Research_Team_Roles
			     INNER JOIN T_Research_Team_Membership
			       ON T_Research_Team_Roles.ID = T_Research_Team_Membership.Role_ID
			     INNER JOIN T_Users
			       ON T_Research_Team_Membership.User_ID = T_Users.ID
			     INNER JOIN T_Campaign
			       ON T_Research_Team_Membership.Team_ID = T_Campaign.CM_Research_Team
			WHERE (T_Campaign.Campaign_ID = @campaignID) AND
			      (T_Research_Team_Roles.ROLE = @role)
		END

		RETURN @result
	END
GO
