/****** Object:  View [dbo].[V_Data_Package_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Data_Package_Entry
AS
SELECT     ID, Name, Package_Type AS PackageType, Description, Comment, Owner, Requester, State, Path_Team AS Team, 
                      Mass_Tag_Database AS MassTagDatabase, Wiki_Page_Link AS PRISMWikiLink, '' AS creationParams
FROM         dbo.T_Data_Package

GO
GRANT SELECT ON [dbo].[V_Data_Package_Entry] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Entry] TO [PNL\D3M580] AS [dbo]
GO
