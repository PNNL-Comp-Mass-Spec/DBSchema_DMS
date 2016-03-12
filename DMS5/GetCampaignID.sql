/****** Object:  StoredProcedure [dbo].[GetCampaignID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE Procedure GetCampaignID
/****************************************************
**
**	Desc: Gets campaignID for given campaign name
**
**	Return values: 0: failure, otherwise, campaign ID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
(
		@campaignNum varchar(80) = " "
)
As
	declare @campaignID int
	set @campaignID = 0
	SELECT @campaignID = Campaign_ID FROM T_Campaign WHERE (Campaign_Num = @campaignNum)
	return(@campaignID)
GO
GRANT EXECUTE ON [dbo].[GetCampaignID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetCampaignID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetCampaignID] TO [PNL\D3M578] AS [dbo]
GO
