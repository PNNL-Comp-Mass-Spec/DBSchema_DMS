/****** Object:  View [dbo].[V_Organism_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_Report]
AS
SELECT OG_name AS Name,
       OG_organismDBPath AS [Org. DB File storage path (client)],
       '' AS [Org. DB File storage path (server)],
       OG_organismDBName AS [Default Org. DB file name]
FROM T_Organisms

GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Report] TO [PNL\D3M580] AS [dbo]
GO
