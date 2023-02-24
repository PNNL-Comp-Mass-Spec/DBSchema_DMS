/****** Object:  StoredProcedure [dbo].[GetCampaignID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCampaignID]
/****************************************************
**
**  Desc: Gets campaignID for given campaign name
**
**  Return values: 0: failure, otherwise, campaign ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**
*****************************************************/
(
    @campaignNum varchar(80) = " "
)
AS
    Set NoCount On

    Declare @campaignID int = 0

    SELECT @campaignID = Campaign_ID
    FROM T_Campaign
    WHERE Campaign_Num = @campaignNum

    return @campaignID
GO
GRANT VIEW DEFINITION ON [dbo].[GetCampaignID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetCampaignID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetCampaignID] TO [Limited_Table_Write] AS [dbo]
GO
