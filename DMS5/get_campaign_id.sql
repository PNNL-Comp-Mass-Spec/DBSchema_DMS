/****** Object:  UserDefinedFunction [dbo].[get_campaign_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_campaign_id]
/****************************************************
**
**  Desc: Gets campaignID for given campaign name
**
**  Return values: 0: failure, otherwise, campaign ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @campaignName varchar(80) = " "
)
RETURNS int
AS
BEGIN
    Declare @campaignID int = 0

    SELECT @campaignID = Campaign_ID
    FROM T_Campaign
    WHERE Campaign_Num = @campaignName

    return @campaignID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_campaign_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_campaign_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_campaign_id] TO [Limited_Table_Write] AS [dbo]
GO
