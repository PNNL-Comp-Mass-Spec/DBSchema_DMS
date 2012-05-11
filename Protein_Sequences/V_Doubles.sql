/****** Object:  View [dbo].[V_Doubles] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Doubles
AS
SELECT     TOP 100 PERCENT dbo.T_Protein_Names.Name, dbo.T_Protein_Names.Description, MIN(dbo.T_Protein_Names.Reference_ID) AS Earliest, 
                      MAX(dbo.T_Protein_Names.Reference_ID) AS Latest
FROM         dbo.V_Temp INNER JOIN
                      dbo.T_Protein_Names ON dbo.V_Temp.Name = dbo.T_Protein_Names.Name AND dbo.V_Temp.Description = dbo.T_Protein_Names.Description
GROUP BY dbo.T_Protein_Names.Name, dbo.T_Protein_Names.Description

GO
