/****** Object:  View [dbo].[V_Organism_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Organism_Picklist
As
SELECT Organism_ID As ID, OG_Name As Name, OG_Description As Description
FROM T_Organisms  
WHERE OG_Active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Picklist] TO [DDL_Viewer] AS [dbo]
GO
