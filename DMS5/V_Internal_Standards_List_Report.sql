/****** Object:  View [dbo].[V_Internal_Standards_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Internal_Standards_List_Report]
AS
SELECT IStds.name,
       IStds.Internal_Std_Mix_ID AS id,
       IStds.description,
       COUNT(ISC.Component_ID) AS components,
       IStds.type,
       ISNULL(ISPM.name, '') AS mix_name,
       ISNULL(ISPM.protein_collection_name, '') AS protein_collection_name,
       IStds.active
FROM dbo.T_Internal_Std_Composition ISC
     RIGHT OUTER JOIN dbo.T_Internal_Std_Parent_Mixes ISPM
       ON ISC.Mix_ID = ISPM.Parent_Mix_ID
     RIGHT OUTER JOIN dbo.T_Internal_Standards IStds
       ON ISPM.Parent_Mix_ID = IStds.Internal_Std_Parent_Mix_ID
GROUP BY IStds.Name, IStds.Description, IStds.TYPE, IStds.Active,
         IStds.Internal_Std_Mix_ID, ISPM.Name, ISPM.Protein_Collection_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Internal_Standards_List_Report] TO [DDL_Viewer] AS [dbo]
GO
