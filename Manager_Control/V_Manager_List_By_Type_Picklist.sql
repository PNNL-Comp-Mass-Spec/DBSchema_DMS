/****** Object:  View [dbo].[V_Manager_List_By_Type_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Manager_List_By_Type_Picklist]
AS
SELECT M.M_ID AS ID,
       M.M_Name AS ManagerName,
       MT.MT_TypeName AS ManagerType
FROM T_Mgrs AS M
     JOIN T_MgrTypes AS MT
       ON M.M_TypeID = MT.MT_TypeID

GO
