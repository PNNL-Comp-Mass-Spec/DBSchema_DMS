/****** Object:  View [dbo].[V_Internal_Standards_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Internal_Standards_List_Report
AS
SELECT dbo.T_Internal_Standards.Name, 
    dbo.T_Internal_Standards.Internal_Std_Mix_ID AS ID, 
    dbo.T_Internal_Standards.Description, 
    COUNT(dbo.T_Internal_Std_Composition.Component_ID) 
    AS Components, dbo.T_Internal_Standards.Type, 
    ISNULL(dbo.T_Internal_Std_Parent_Mixes.Name, '') 
    AS [Mix Name], 
    ISNULL(dbo.T_Internal_Std_Parent_Mixes.Protein_Collection_Name,
     '') AS Protein_Collection_Name, 
    dbo.T_Internal_Standards.Active
FROM dbo.T_Internal_Std_Composition INNER JOIN
    dbo.T_Internal_Std_Parent_Mixes ON 
    dbo.T_Internal_Std_Composition.Mix_ID = dbo.T_Internal_Std_Parent_Mixes.Parent_Mix_ID
     RIGHT OUTER JOIN
    dbo.T_Internal_Standards ON 
    dbo.T_Internal_Std_Parent_Mixes.Parent_Mix_ID = dbo.T_Internal_Standards.Internal_Std_Parent_Mix_ID
GROUP BY dbo.T_Internal_Standards.Name, 
    dbo.T_Internal_Standards.Description, 
    dbo.T_Internal_Standards.Type, 
    dbo.T_Internal_Standards.Active, 
    dbo.T_Internal_Standards.Internal_Std_Mix_ID, 
    dbo.T_Internal_Std_Parent_Mixes.Name, 
    dbo.T_Internal_Std_Parent_Mixes.Protein_Collection_Name

GO
