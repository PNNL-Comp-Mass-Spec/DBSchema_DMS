/****** Object:  View [dbo].[V_DEPkgr_Campaigns] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW V_DEPkgr_Campaigns
as
SELECT     Campaign_ID, Campaign_Num AS Campaign_Name, CM_Project_Num AS Project_Number, dbo.GetCampaignRolePerson(Campaign_ID, 'Project Mgr') 
                      AS Project_Manager_PRN, dbo.GetCampaignRolePerson(Campaign_ID, 'PI') AS Principal_Inv_PRN, CM_comment AS Comments, 
                      CM_created AS Date_Created
FROM         T_Campaign  

GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Campaigns] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Campaigns] TO [PNL\D3M580] AS [dbo]
GO
