/****** Object:  View [dbo].[V_Manager_Type_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Manager_Type_Report_Ex]
AS
SELECT MT.MT_TypeName AS Manager_Type,
       MT.MT_TypeID AS ID,
       ISNULL(ActiveManagersQ.ManagerCountActive, 0) AS Manager_Count_Active,
       ISNULL(ActiveManagersQ.ManagerCountInactive, 0) AS Manager_Count_Inactive
FROM dbo.T_MgrTypes AS MT
     LEFT OUTER JOIN ( SELECT Mgr_Type_ID,
                              Manager_Type,
                              SUM(CASE WHEN active = 'True' THEN 1 ELSE 0 END) AS ManagerCountActive,
                              SUM(CASE WHEN active <> 'True' THEN 1 ELSE 0 END) AS ManagerCountInactive
                       FROM dbo.V_Manager_List_By_Type
                       GROUP BY Mgr_Type_ID, Manager_Type ) AS ActiveManagersQ
       ON MT.MT_TypeID = ActiveManagersQ.Mgr_Type_ID


GO
