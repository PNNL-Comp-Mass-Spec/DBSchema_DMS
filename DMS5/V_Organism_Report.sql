/****** Object:  View [dbo].[V_Organism_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_Report]
AS
SELECT OG_name AS Name,
       OG_organismDBPath AS Org_DB_File_storage_path_client,
       '' AS Org_DB_File_storage_path_server,
       OG_organismDBName AS Default_Org_DB_file_name
FROM T_Organisms


GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Report] TO [DDL_Viewer] AS [dbo]
GO
