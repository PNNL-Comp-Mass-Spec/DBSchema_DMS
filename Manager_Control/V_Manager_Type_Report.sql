/****** Object:  View [dbo].[V_Manager_Type_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Manager_Type_Report]
AS
SELECT MT.MT_TypeName AS manager_type,
       MT.MT_TypeID AS id,
       ISNULL(ActiveManagersQ.managercountactive, 0) AS manager_count_active,
       ISNULL(ActiveManagersQ.managercountinactive, 0) AS manager_count_inactive
FROM dbo.T_MgrTypes AS MT
     LEFT OUTER JOIN ( SELECT Mgr_Type_ID,
                              Manager_Type,
                              SUM(CASE WHEN active = 'True' THEN 1 ELSE 0 END) AS ManagerCountActive,
                              SUM(CASE WHEN active <> 'True' THEN 1 ELSE 0 END) AS ManagerCountInactive
                       FROM dbo.V_Manager_List_By_Type
                       GROUP BY Mgr_Type_ID, Manager_Type ) AS ActiveManagersQ
       ON MT.MT_TypeID = ActiveManagersQ.Mgr_Type_ID
WHERE (MT.MT_TypeID IN ( SELECT M_TypeID
                         FROM dbo.T_Mgrs
                         WHERE (M_ControlFromWebsite > 0) ))


GO
