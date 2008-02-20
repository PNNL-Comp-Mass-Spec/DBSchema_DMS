/****** Object:  View [dbo].[V_Campaign_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Campaign_List_Report_2
AS
SELECT     Campaign_ID AS ID, Campaign_Num AS Campaign, CM_Project_Num AS Project, CM_Proj_Mgr_PRN AS ProjectMgr, CM_PI_PRN AS PI, 
                      CM_comment AS Comment, CM_created AS Created
FROM         dbo.T_Campaign

GO
