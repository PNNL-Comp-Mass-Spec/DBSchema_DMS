/****** Object:  View [dbo].[V_Helper_Organism_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Helper_Organism_List_Report]
AS
SELECT     Organism_ID AS ID, OG_name AS Name, OG_Genus AS Genus, OG_Species AS Species, OG_Strain AS Strain, OG_description AS Description, 
                      OG_created AS Created, OG_Active AS Active
FROM         T_Organisms
WHERE     (OG_name <> '(default)')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Organism_List_Report] TO [DDL_Viewer] AS [dbo]
GO
