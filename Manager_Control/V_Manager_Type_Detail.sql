/****** Object:  View [dbo].[V_Manager_Type_Detail] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Manager_Type_Detail]
AS
SELECT MT_TYPEID AS ID, '' AS manager_List
FROM T_MgrTypes

GO
