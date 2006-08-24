/****** Object:  View [dbo].[V_DEPkgr_Campaigns] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_Campaigns
AS
SELECT     Campaign_ID, Campaign_Num AS Campaign_Name, CM_Project_Num AS Project_Number, CM_Proj_Mgr_PRN AS Project_Manager_PRN, 
                      CM_PI_PRN AS Principal_Inv_PRN, CM_comment AS Comments, CM_created AS Date_Created
FROM         dbo.T_Campaign

GO
