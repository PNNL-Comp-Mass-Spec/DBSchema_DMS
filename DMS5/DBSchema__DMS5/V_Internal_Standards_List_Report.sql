/****** Object:  View [dbo].[V_Internal_Standards_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Internal_Standards_List_Report
AS
SELECT     T_Internal_Standards.Name, T_Internal_Standards.Internal_Std_Mix_ID AS ID, T_Internal_Standards.Description, 
                      COUNT(T_Internal_Std_Composition.Component_ID) AS Components, T_Internal_Standards.Type, T_Internal_Standards.Active
FROM         T_Internal_Standards LEFT OUTER JOIN
                      T_Internal_Std_Composition ON T_Internal_Standards.Internal_Std_Mix_ID = T_Internal_Std_Composition.Mix_ID
GROUP BY T_Internal_Standards.Name, T_Internal_Standards.Description, T_Internal_Standards.Type, T_Internal_Standards.Active, 
                      T_Internal_Standards.Internal_Std_Mix_ID

GO
