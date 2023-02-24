/****** Object:  UserDefinedFunction [dbo].[GetCampaignRolePersonList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetCampaignRolePersonList]
/****************************************************
**
**  Desc:
**  Returns list of people for given role
**  for the given campaign
**
**  Return value: person
**
**  Parameters:
**
**  Auth:   grk
**  Date:   02/04/2010
**          12/08/2014 mem - Now using Name_with_PRN to obtain each user's name and PRN
**
*****************************************************/
(
    @campaignID INT,
    @role VARCHAR(64),
    @mode VARCHAR(24) = 'PRN'
)
RETURNS varchar(6000)
AS
    BEGIN
        declare @list varchar(6000)
        set @list = ''

        IF NOT (@campaignID IS NULL OR @role IS NULL)
        BEGIN
            SELECT @list = @list + CASE WHEN @list = '' THEN ''
                                        ELSE ', '
                                   END +
                                   CASE WHEN @mode = 'PRN' THEN T_Users.U_PRN
                                        ELSE T_Users.Name_with_PRN
                                   END
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

        RETURN @list
    END
GO
GRANT VIEW DEFINITION ON [dbo].[GetCampaignRolePersonList] TO [DDL_Viewer] AS [dbo]
GO
