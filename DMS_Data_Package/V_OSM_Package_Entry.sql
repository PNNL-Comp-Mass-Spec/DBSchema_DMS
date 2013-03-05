/****** Object:  View [dbo].[V_OSM_Package_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_OSM_Package_Entry] AS 
 SELECT 
	ID AS ID,
	Name AS Name,
	Package_Type AS PackageType,
	Description AS Description,
	Keywords AS Keywords,
	Comment AS Comment,
	Owner AS Owner,
	[State] AS State
FROM T_OSM_Package

GO
