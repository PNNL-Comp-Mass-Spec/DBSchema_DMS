/****** Object:  View [dbo].[V_Analysis_Job_Processors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  View [dbo].[V_Analysis_Job_Processors_List_Report] ******/
CREATE VIEW [dbo].[V_Analysis_Job_Processors_List_Report]
AS
SELECT     T_Mgrs.M_ID AS ID, T_Mgrs.M_Name AS Name, T_MgrTypes.MT_TypeName AS Type
FROM         T_Mgrs INNER JOIN
                      T_MgrTypes ON T_Mgrs.M_TypeID = T_MgrTypes.MT_TypeID
GO
