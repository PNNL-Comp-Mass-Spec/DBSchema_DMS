/****** Object:  View [dbo].[V_Ext_PGDump_Organisms_Aj] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Organisms_Aj
AS
SELECT	Organism_ID AS id, 
		OG_name AS name, 
		CASE WHEN OG_genus IS NOT NULL 
			THEN COALESCE (OG_Genus, '') + ' ' + COALESCE (OG_Species, '') + ' ' + COALESCE (OG_Strain, '') 
			ELSE [OG_name] 
			END AS full_name,
		AJ.AJ_JobId AS aj_id
FROM	T_Organisms O
		JOIN T_Analysis_Job AJ ON AJ.AJ_organismID = O.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Organisms_Aj] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Organisms_Aj] TO [PNL\D3M580] AS [dbo]
GO
