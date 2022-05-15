/****** Object:  View [dbo].[V_Data_Package_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Entry]
AS
SELECT id,
       name,
       package_type,
       description,
       [comment],
       owner,
       requester,
       state,
       Path_Team AS team,
       Mass_Tag_Database AS mass_tag_database,
       Wiki_Page_Link AS prismwiki_link,
       data_doi,
       manuscript_doi,
       '' AS creation_params
FROM dbo.T_Data_Package

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Entry] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_Entry] TO [DMS_SP_User] AS [dbo]
GO
