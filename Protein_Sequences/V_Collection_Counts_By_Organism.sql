/****** Object:  View [dbo].[V_Collection_Counts_By_Organism] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Collection_Counts_By_Organism
AS
SELECT     LOWER(dbo.V_Organism_Picker.Short_Name) AS organism_name, COUNT(dbo.V_Collection_Picker.ID) AS count, 
                      dbo.V_Organism_Picker.ID AS id
FROM         dbo.V_Organism_Picker LEFT OUTER JOIN
                      dbo.V_Collection_Picker ON dbo.V_Organism_Picker.Short_Name = dbo.V_Collection_Picker.Organism_Name
GROUP BY dbo.V_Organism_Picker.Short_Name, dbo.V_Organism_Picker.ID

GO
