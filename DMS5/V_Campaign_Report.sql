/****** Object:  View [dbo].[V_Campaign_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Campaign_Report]
AS
SELECT Campaign_Num AS campaign,
       CM_Project_Num AS project,
       dbo.GetCampaignRolePerson(Campaign_ID, 'Project Mgr') AS project_mgr,
       dbo.GetCampaignRolePerson(Campaign_ID, 'PI') AS pi,
       CM_comment AS comment,
       CM_created AS created,
       CM_State As state
FROM T_Campaign


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Report] TO [DDL_Viewer] AS [dbo]
GO
