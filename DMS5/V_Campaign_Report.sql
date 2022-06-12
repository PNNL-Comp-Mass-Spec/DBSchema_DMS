/****** Object:  View [dbo].[V_Campaign_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Campaign_Report]
AS
SELECT Campaign_Num AS Campaign,
       CM_Project_Num AS Project,
       dbo.GetCampaignRolePerson(Campaign_ID, 'Project Mgr') AS ProjectMgr,
       dbo.GetCampaignRolePerson(Campaign_ID, 'PI') AS PI,
       CM_comment AS Comment,
       CM_created AS Created,
       CM_State As State
FROM T_Campaign


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Report] TO [DDL_Viewer] AS [dbo]
GO
