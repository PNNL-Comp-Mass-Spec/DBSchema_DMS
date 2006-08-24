/****** Object:  View [dbo].[V_Internal_Standards_Composition_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW dbo.V_Internal_Standards_Composition_Report
AS
SELECT     T_Internal_Std_Components.Name AS Component, T_Internal_Std_Components.Description AS [Component Description], 
                      T_Internal_Std_Composition.Concentration, T_Internal_Std_Components.Monoisotopic_Mass, T_Internal_Std_Components.Charge_Minimum, 
                      T_Internal_Std_Components.Charge_Maximum, T_Internal_Std_Components.Charge_Highest_Abu, T_Internal_Std_Components.Expected_GANET, 
                      T_Internal_Std_Components.Internal_Std_Component_ID AS ID, T_Internal_Standards.Name AS [#Name]
FROM         T_Internal_Standards INNER JOIN
                      T_Internal_Std_Composition ON T_Internal_Standards.Internal_Std_Mix_ID = T_Internal_Std_Composition.Mix_ID INNER JOIN
                      T_Internal_Std_Components ON T_Internal_Std_Composition.Component_ID = T_Internal_Std_Components.Internal_Std_Component_ID


GO
