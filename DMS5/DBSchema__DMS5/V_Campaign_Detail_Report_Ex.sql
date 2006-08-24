/****** Object:  View [dbo].[V_Campaign_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW dbo.V_Campaign_Detail_Report_Ex
AS
SELECT T_Campaign.Campaign_Num AS Campaign, 
   T_Campaign.CM_Project_Num AS Project, 
   V_Users.U_Name + ' (' + T_Campaign.CM_Proj_Mgr_PRN + ')' AS ProjectMgr,
    T_Users.U_Name + ' (' + T_Campaign.CM_PI_PRN + ')' AS PI, 
   T_Campaign.CM_comment AS Comment, 
   T_Campaign.CM_created AS Created
FROM T_Campaign INNER JOIN
   T_Users ON 
   T_Campaign.CM_PI_PRN = T_Users.U_PRN INNER JOIN
   V_Users ON T_Campaign.CM_Proj_Mgr_PRN = V_Users.U_PRN
GO
