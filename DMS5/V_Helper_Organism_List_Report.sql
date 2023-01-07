/****** Object:  View [dbo].[V_Helper_Organism_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Helper_Organism_List_Report]
AS
SELECT Organism_ID AS id, OG_name AS name, OG_Genus AS genus, OG_Species AS species, OG_Strain AS strain, OG_description AS description,
       OG_created AS created, OG_Active AS Active
FROM T_Organisms
WHERE OG_name <> '(default)'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Organism_List_Report] TO [DDL_Viewer] AS [dbo]
GO
