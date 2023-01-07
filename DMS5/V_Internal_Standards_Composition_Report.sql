/****** Object:  View [dbo].[V_Internal_Standards_Composition_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Internal_Standards_Composition_Report
AS
SELECT dbo.T_Internal_Std_Components.Name AS component,
    dbo.T_Internal_Std_Components.Description AS component_description,
     dbo.T_Internal_Std_Composition.concentration,
    dbo.T_Internal_Std_Components.monoisotopic_mass,
    dbo.T_Internal_Std_Components.charge_minimum,
    dbo.T_Internal_Std_Components.charge_maximum,
    dbo.T_Internal_Std_Components.charge_highest_abu,
    dbo.T_Internal_Std_Components.expected_ganet,
    dbo.T_Internal_Std_Components.internal_std_component_id AS id,
    dbo.T_Internal_Standards.Name AS name
FROM dbo.T_Internal_Std_Parent_Mixes INNER JOIN
    dbo.T_Internal_Standards ON
    dbo.T_Internal_Std_Parent_Mixes.Parent_Mix_ID = dbo.T_Internal_Standards.Internal_Std_Parent_Mix_ID
     INNER JOIN
    dbo.T_Internal_Std_Components INNER JOIN
    dbo.T_Internal_Std_Composition ON
    dbo.T_Internal_Std_Components.Internal_Std_Component_ID = dbo.T_Internal_Std_Composition.Component_ID
     ON
    dbo.T_Internal_Std_Parent_Mixes.Parent_Mix_ID = dbo.T_Internal_Std_Composition.Mix_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Internal_Standards_Composition_Report] TO [DDL_Viewer] AS [dbo]
GO
