/****** Object:  View [dbo].[V_Protein_Collection_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Collection_Name
AS
SELECT     Name, Type, Description, Entries, [Organism Name], ID
FROM         (SELECT     Name, Type, Description, Entries, CASE WHEN Type = 'Internal_Standard' OR
                                              Type = 'contaminant' THEN '' ELSE Organism_Name END AS [Organism Name], ID, 
                                              CASE WHEN type = 'internal_standard' THEN 1 WHEN type = 'contaminant' THEN 2 ELSE 0 END AS TypeSortOrder
                       FROM          Protein_Sequences.dbo.V_Collection_Picker) AS LookupQ
GROUP BY Name, Type, Description, Entries, [Organism Name], ID, TypeSortOrder

GO
